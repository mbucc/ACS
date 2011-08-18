# $Id: ad-content-tagging.tcl,v 3.0 2000/02/06 03:12:15 ron Exp $
# ad-content-tagging.tcl
# by aure@arsdigita.com May 1999

# helper procedures for the Content Tagging system

proc_doc naughty_content_mask_for_user {user_id} "Queries database and returns content mask for user or the system-wide DefaultContentMask if we get a NULL or no row back from the database." {
    set db [ns_db gethandle subquery]
    set content_mask [database_to_tcl_string_or_null $db "select content_mask from users_preferences where user_id=$user_id"]
    if {[empty_string_p $content_mask]} {
	set content_mask [ad_parameter DefaultContentMask "content-tagging" 0]
    }
    ns_db releasehandle $db
    return $content_mask
}

proc_doc apply_content_mask {tag} {Returns the bitwise AND of the content tag arg with the currently connected user's content preference} {
    set user_id [ad_get_user_id]
    if { $user_id == 0 } {
	# not logged in 
	set content_mask [ad_parameter DefaultContentMask "content-tagging" 0]
    } else {
	# logged in
	set content_mask [util_memoize "naughty_content_mask_for_user $user_id" [ad_parameter UserContentMaskCacheTimeout "content-tagging" 600]]
    }
    return [expr $tag&$content_mask]
}

proc_doc tag_content {text} {Yields content tag associated with the text} {
    ns_share tag_array
    set user_id [ad_get_user_id]
    util_memoize "get_content_tags" [ad_parameter CacheTimeout content-tagging]
    
    set text [ns_striphtml [string tolower $text]]
    # replace one or more non-alphanumerics into 
    # one space to make a Tcl list
    regsub -all {[^A-z0-9 ]+} $text " " text
    set returned_tag 0
    foreach word $text { 
	if [info exists tag_array($word)] {
	    set returned_tag [expr $tag_array($word)|$returned_tag]
	}
    }
    return $returned_tag
}

proc_doc naughty_loggable_naughtiness_mask {} "Returns a mask suitable for ANDing with a content tag.  If the result is non-zero, you've got loggable naughtiness." {
    set loggable_naughtiness 0
    if {[ad_parameter XLogP content-tagging]} {
	incr loggable_naughtiness 4
    }
    if {[ad_parameter RLogP content-tagging]} {
	incr loggable_naughtiness 2
    }
    if {[ad_parameter PGLogP content-tagging]} {
	incr loggable_naughtiness 1
    }
    return $loggable_naughtiness
}

proc_doc naughty_bounceable_naughtiness_mask {} "Returns a mask suitable for ANDing with a content tag.  If the result is non-zero, you've got bounceable naughtiness." {
    set bounceable_naughtiness 0
    if {[ad_parameter XBounceP content-tagging]} {
	incr bounceable_naughtiness 4
    }
    if {[ad_parameter RBounceP content-tagging]} {
	incr bounceable_naughtiness 2 
    }
    if {[ad_parameter PGBounceP content-tagging]} {
	incr bounceable_naughtiness 1
    }
    return $bounceable_naughtiness
}

proc_doc naughty_notifiable_naughtiness_mask {} "Returns a mask suitable for ANDing with a content tag.  If the result is non-zero, you've got notifiable naughtiness." {
    set notifiable_naughtiness 0
    if {[ad_parameter XBounceP content-tagging]} {
	incr notifiable_naughtiness 4
    }
    if {[ad_parameter RBounceP content-tagging]} {
	incr notifiable_naughtiness 2 
    }
    if {[ad_parameter PGBounceP content-tagging]} {
	incr notifiable_naughtiness 1
    }
    return $notifiable_naughtiness
}

proc_doc content_string_ok_for_site_p {text {table_name ""} {the_key ""}} {Determines whether text being suggested for the site should be logged or bounced and if an administrator should be notified} {
    set loggable_naughtiness [util_memoize naughty_loggable_naughtiness_mask]
    set bounceable_naughtiness [util_memoize naughty_bounceable_naughtiness_mask]
    set notifiable_naughtiness [util_memoize naughty_notifiable_naughtiness_mask]
    set user_id [ad_get_user_id] 
    
    set content_tag [tag_content $text]
    
    if { $content_tag&$loggable_naughtiness && $user_id != 0 } {
	set db [ns_db gethandle subquery]
	ns_ora clob_dml $db "insert into naughty_events 
(table_name, the_key, offensive_text, creation_user, creation_date) 
values
('$table_name','[DoubleApos $the_key]',empty_clob(),$user_id, sysdate)
returning offensive_text into :1" $text
        ns_db releasehandle $db      
    }

    if { $content_tag&$notifiable_naughtiness } {
	set db [ns_db gethandle subquery]
	set selection [ns_db 0or1row $db "select first_names, last_name, email from users where user_id = $user_id"]
	if [empty_string_p $selection] {
	    set user_description "unknown user"
	} else {
	    set_variables_after_query
	    set user_description "$first_names $last_name ($email)"
	}
	naughty_notify_admin "$user_description being naughty at [ad_url]" "Here's what $user_description posted at [ad_url]:

$text

Table:  $table_name
"
        ns_db releasehandle $db      
    }
    if { $content_tag & $bounceable_naughtiness } {
	return 1
    } else {
	return 0
    }
}

proc_doc bowdlerization_level {} {Returns bowdlerization mask for site, if ANDed with a word's mask and result is non-zero, replace with something innocuous} {
    set bowdlerization_level 0
    if {[ad_parameter XBowdlerizeP content-tagging]} {
	incr bowdlerization_level 4
    }
    if {[ad_parameter RBowdlerizeP content-tagging]} {
	incr bowdlerization_level 2
    }
    if {[ad_parameter PGBowdlerizeP content-tagging]} {
	incr bowdlerization_level 1
    }
    return $bowdlerization_level
}

# in Oracle 8.1, convert this query to use the PL/SQL proc utl_raw.bit_and
# and not get irrelevant words from the db in the first place
proc naughty_words_for_level {bowdlerization_level} {
    # Returns list of | separated words which are to be restricted
    # at the given bowdlerization level.
    set db [ns_db gethandle subquery]

    set selection [ns_db select $db "select word, tag
from content_tags
order by tag desc"]

    set naughty_words [list]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	if { $tag & $bowdlerization_level } {
	    lappend naughty_words $word
	}
    }
    ns_db releasehandle $db
    return [join $naughty_words "|"]
}

proc_doc bowdlerize_text {text} {Returns bowdlerized version of TEXT or empty string if no bowdlerization was necessary} {
    ns_share tag_array
    set user_id [ad_get_user_id]    

    set timeout [ad_parameter CacheTimeout content-tagging]

    set bowdlerization_level [util_memoize "bowdlerization_level"]
    set naughty_words [util_memoize "naughty_words_for_level $bowdlerization_level" $timeout]

    if { [empty_string_p $naughty_words] } {
	# publisher hasn't defined any naughty words at this level
	return ""
    }

    set replacement_text [ad_parameter BowdlerizationText content-tagging]

    # Solely naughty words.
    set bowdler_re1 "^($naughty_words)\$"
    set bowdler_replace_str1 $replacement_text

    # Embedded naughty words.
    set bowdler_re2 "(\[^A-Za-z0-9\])($naughty_words)(\[^A-Za-z0-9\])"
    set bowdler_replace_str2 "\\1$replacement_text\\3"
    
    # Naughty words at the beginning.
    set bowdler_re3 "^($naughty_words)(\[^A-Za-z0-9\])"
    set bowdler_replace_str3 "$replacement_text\\2"
    
    # Naughty words at the end.
    set bowdler_re4 "(\[^A-Za-z0-9\])($naughty_words)\$"
    set bowdler_replace_str4 "\\1$replacement_text"

    
    if { [regsub -all -nocase $bowdler_re1 $text $bowdler_replace_str1 text] 
	 + [regsub -all -nocase $bowdler_re2 $text $bowdler_replace_str2 text] 
	 + [regsub -all -nocase $bowdler_re3 $text $bowdler_replace_str3 text] 
	 + [regsub -all -nocase $bowdler_re4 $text $bowdler_replace_str4 text] } {
	return $text
    } else {
	return ""
    }
}



proc_doc get_content_tags {} {Load the naughty words into a shared tcl array entitled tag_array} {

    set db [ns_db gethandle subquery]
    ns_share tag_array
    set sql "select word, tag from content_tags order by tag desc"
    set selection [ns_db select $db $sql]
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	set tag_array($word) $tag
    }
    ns_db releasehandle $db
}

proc_doc naughty_administrator {} "Returns email address of person to notify if naughty content is added" {
    if [empty_string_p [ad_parameter Administrator content-tagging]] {
	return [ad_system_owner]
    } else {
	return [ad_parameter Administrator content-tagging]
    }
}


ns_share -init { set naughty_administrator_last_notified 0 } naughty_administrator_last_notified

proc_doc naughty_notify_admin {subject body {log_p 0}} "Notify Content Administrator of new naughtiness added" {
    ns_share naughty_administrator_last_notified
    ns_share accumulated_naughtiness
    if $log_p {
	# usually the naughty text will be in the database anyway
	ns_log Notice "notify_naughty_admin: $subject\n\n$body\n\n"
    }
    if { [ns_time] > [expr $naughty_administrator_last_notified + 900] } {
	# more than 15 minutes have elapsed since last note
	set naughty_administrator_last_notified [ns_time]
	if [info exists accumulated_naughtiness] {
	    append body $accumulated_naughtiness
	}
	if [catch { ns_sendmail [naughty_administrator] [ad_system_owner] $subject $body } errmsg] {
	    ns_log Error "naughty_notify_admin failed sending email note to [naughty_administrator]"
	}
	# we're done sending body and accumulated naughtiness; reset var if necessary
	if [info exists accumulated_naughtiness] {
	    unset accumulated_naughtiness
	}
    } else {
	append accumulated_naughtiness "----------------------- [ns_localsqltimestamp]

Subject: $subject

BODY:

$body 

"
    }
}
