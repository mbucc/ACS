# /tcl/gc-defs.tcl

ad_library {
    definitions for the classified ads system

    @author philg@mit.edu
    @creation-date back in the Jurassic period (1996?)
    @cvs-id gc-defs.tcl,v 3.4.2.7 2000/08/14 21:40:04 ron Exp
}

proc gc_system_name {} {
    set default "[ad_system_name] Classifieds"
    return [ad_parameter SystemName gc $default]
}

proc gc_system_url {} {
    return "[ad_url][ad_parameter PartialUrlStub gc "/gc/"]"
}

proc gc_system_owner {} {
    return [ad_parameter SystemOwner gc [ad_system_owner]]
}

proc gc_header {page_title} {
    return [ad_header $page_title]
}

proc gc_footer {signatory} {
    return "<hr>
<a href=\"mailto:$signatory\"><address>$signatory</address></a>
</body>
</html>
"
}

proc gc_search_active_p {} {
    return [ad_parameter ProvideLocalSearchP gc 0]
}

proc gc_query_for_domain_info {domain_id {extra_columns ""}} {
    return "select domain, full_noun, domain_type, auction_p, geocentric_p, wtb_common_p, primary_maintainer_id, 
                   $extra_columns users.email as maintainer_email
            from ad_domains, users
            where domain_id = :domain_id
            and primary_maintainer_id = users.user_id"
}

# cache the grouping stuff for the cover page

proc gc_categories_for_one_domain {domain_id} {    
    db_foreach category_list {
	select count(*) as count,primary_category as category
	from classified_ads
	where domain_id = :domain_id
	and (sysdate <= expires or expires is null)
	group by primary_category
	order by upper(primary_category)
    } {
	set url "view-category.tcl?domain_id=[ns_urlencode $domain_id]&primary_category=[ns_urlencode $category]"
	if { $count == 1 } {
	    set pretty_count "1 Ad"
	} else {
	    set pretty_count "$count Ads"
	}
	append result "<li><a href=\"$url\">$category</a> ($pretty_count)"
    }
    if { ![info exists result] } {
	return "No ads found; probably they've all expired."
    } else {
	return $result
    }
}

# audit insert

proc gc_audit_insert {classified_ad_id {deleted_by_admin_p 0}} {
    if $deleted_by_admin_p {
	set admin_column ",\ndeleted_by_admin_p"
	set admin_value ",\n  't'"
    } else {
	set admin_column ""
	set admin_value ""
    }
    return  "insert into classified_ads_audit 
 (classified_ad_id,
  user_id,
  domain_id,
  originating_ip,
  posted,
  expires,
  wanted_p,
  private_p,
  primary_category,
  subcategory_1,
  subcategory_2,
  manufacturer,
  model,
  one_line,
  full_ad,
  html_p,
  last_modified,
  audit_ip$admin_column)
select 
  classified_ad_id,
  user_id,
  domain_id,
  originating_ip,
  posted,
  expires,
  wanted_p,
  private_p,
  primary_category,
  subcategory_1,
  subcategory_2,
  manufacturer,
  model,
  one_line,
  full_ad,
  html_p,
  last_modified,
 '[DoubleApos [ns_conn peeraddr]]'$admin_value
from classified_ads where classified_ad_id = $classified_ad_id"
}

# spamming system

proc gc_PrettyFrequency {frequency} {
    switch $frequency {
	daily   { return Daily }
	weekly  { return Weekly }
	monthu  { return Monday/Thursday }
	instant { return Instantly }
	
	default { 
	    error "Unrecognized frequency: $frequency"
	}
    }
}

proc gc_spam {frequency} {
    # we could just update classified_email_alerts_last_updates
    # right now but we don't because we might get interrupted

    if {[lsearch [list weekly daily monthu] $frequency] == -1} {
	ns_log Error "Someone tried to call gc_spam with frequency $frequency"
	return
    }

    set start_time [db_string gc_start_time "
    select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') from dual"]

    ns_log Notice "GC started spamming $frequency at $start_time.\n\n"
    
    # frequency is a column name, not a variable
    set last_time [db_string gc_spam_frequency "
    select unique to_char($frequency,'YYYY-MM-DD HH24:MI:SS') from classified_alerts_last_updates"]

    set mail_counter 0

    db_foreach alert_list {	
	select classified_email_alerts.*, 
               classified_email_alerts.alert_id,  
               users_alertable.email 
	from   classified_email_alerts,  
               users_alertable
	where  users_alertable.user_id = classified_email_alerts.user_id
	and    valid_p = 't'
	and    frequency = :frequency
	and    sysdate <= expires 
    } {
	# this is the outer loop where each row is an alert for one email address

	switch $alert_type {

	    all {
		# the query is simple
		set query {
		    select classified_ads.*, users.email as poster_email
		    from   classified_ads, users
		    where  classified_ads.user_id=users.user_id 
		    and    domain_id = :domain_id
		    and    (expires > sysdate or expires is NULL) 
		    and    (last_modified > to_date(:last_time, 'YYYY-MM-DD HH24:MI:SS'))
		    order by classified_ad_id desc
		}
	    }

	    category {
		set query {
		    select classified_ads.*, users.email as poster_email
		    from   classified_ads, users
		    where  classified_ads.user_id = users.user_id 
		    and    domain_id = :domain_id
		    and    primary_category = :category
		    and    (expires > sysdate or expires is NULL) 
		    and    (last_modified > to_date(:last_time, 'YYYY-MM-DD HH24:MI:SS'))
		    order by classified_ad_id desc
		}
	    }
	    
	    keywords {
		set query {
		    select classified_ads.*, users.email as poster_email
		    from   classified_ads, users
		    where  classified_ads.user_id = users.user_id 
		    and    domain_id = :domain_id
		    and    pseudo_contains(users.first_names||users.last_name||users.email||one_line||full_ad, :keywords) > 0
		    and    (expires > sysdate or expires is NULL) 
		    and    (last_modified > to_date(:last_time, 'YYYY-MM-DD HH24:MI:SS'))
		    order by classified_ad_id desc
		}
	    }

	    default {
		ns_log Notice "gc: bad alert_type"
		return
	    }
	}
	
	set n_rows 0
	set error_p 0
	set msg_body ""
	set id_list ""

	set recipients $email
	db_foreach rows_process $query {
	    # this is the inner loop where each row
	    # is an ad that corresponds to an alert
	    
	    incr n_rows
	    lappend id_list $classified_ad_id
	    if [string equal $howmuch "everything"] {
		# user wants the whole ad
		append msg_body "--------------- Ad $classified_ad_id from $poster_email\n\n"
		append msg_body "Subject: $one_line\n\n"
		append msg_body "[ns_striphtml $full_ad]\n\n"
	    } else {
		# user only wants one line/ad
		append msg_body "$one_line ($classified_ad_id, $poster_email)\n"
	    }
	}

	if ![empty_string_p $msg_body] {
	    # we have something to send
	    if {!$error_p} {
		# there was no error, so let's add a little something...
		# turn spaces into %20's
		set id_list_for_url [ns_urlencode $id_list]
		append msg_body "\nIf you love the Web and want to check out a Web page
		of these ads, just cut and paste the following URL:
	    
		[gc_system_url]alert-summary?id_list=$id_list_for_url

		I hope you enjoy this service of [gc_system_name], which you'll find at
		[gc_system_url]
	    
		Yours,
	    
		a little bit of NaviServer Tcl API and SQL code
	    
		Note: if you really are annoyed by this message then just enter the
		following URL into a browser and you'll disable the alert that
		generated this mail:
	    
		[gc_system_url]alert-disable?alert_id=[ns_urlencode $alert_id]
		"
	    }
	}

	if [catch { 
	    ns_sendmail $recipients [gc_system_owner] "Recent ads from [gc_system_name]" $msg_body 
	} errmsg] {
	    ns_log Notice "error sending gc_spam to \"$recipients\" $errmsg"
	    
	} else {
	    ns_log Notice "Sent mail to $recipients.\n"
	    incr mail_counter
	}
    }

    # we're done with all the alerts

    db_dml alerts_update "
        update classified_alerts_last_updates 
	set $frequency = to_date(:start_time, 'YYYY-MM-DD HH24:MI:SS'),
	    $frequency\_total = $frequency\_total + :mail_counter
    "
    
    ns_log Notice "GC AlertSpam completed for $frequency; $mail_counter msgs sent.\n"
}


proc gc_spam_daily {} {
    gc_spam daily
}
proc gc_spam_monthu {} {
    gc_spam monthu
}
proc gc_spam_weekly {} {
    gc_spam weekly
}

proc gc_ad_owner_spam {} {
    ns_log Notice "Starting classfieds gc_ad_owner_spam at [ns_localsqltimestamp]"
   
    set generic_preamble "

    In the interests of having a well-groomed classified ad system for
    everyone, we're sending you this robotically generated message to
    remind you to
    
    1) delete ads for items that have sold
    2) consider updating the price on items that haven't sold
    3) delete duplicate ads
    
    It is effort like this on the part of the users that makes it possible
    to offer this service for free.
    
    Here are the ads you've placed to date:
    "

    set generic_postamble "

    Thank you for using [gc_system_name]
    (at [gc_system_url]).
    "

    set sql {
	select max(classified_ads.user_id) as user_id, max(domain_id) as domain_id, 
	       max(last_modified) as most_recent_visit, min(last_modified) as least_recent_visit,
	       count(classified_ads.user_id) as n_ads
	from classified_ads
	where (sysdate <= expires or expires is null)
	and (wanted_p <> 't' or sysdate > (last_modified + 30))
	and sysdate > last_modified + 6
	group by user_id
    }
    db_foreach ad_list $sql {
	set sql_sub {
	    select classified_ad_id, posted, last_modified, one_line, expired_p(expires) as expired_p, users.email
	    from classified_ads, users
	    where classified_ads.user_id = users.user_id
	    and classified_ads.user_id = :user_id
	    order by expired_p, classified_ad_id desc
	}
        if { $n_ads == 1 } {
	    set subject_line "your ad in [gc_system_name]"
	} else {
	    set subject_line "your $n_ads ads in [gc_system_name]"
	}
	set body $generic_preamble
	set expired_section_started_yet_p 0

	db_foreach ad_sublist $sql_sub {	    
	    if { $last_modified == $posted || $last_modified == "" } {
		set modified_phrase ""
	    } else {
		set modified_phrase "(modified $last_modified)"
	    }
	    if { $expired_p == "t" } {
		if { !$expired_section_started_yet_p } {
		    append body "\n    -- expired ads --  \n\n"
		    set expired_section_started_yet_p 1
		}
		set expired_phrase "(EXPIRED)"
	    } else {
		set expired_phrase ""
	    }
 
	    append body "${posted}${expired_phrase} : $one_line $modified_phrase
[gc_system_url]edit-ad-3.tcl?classified_ad_id=$classified_ad_id
"
    }

       if { $expired_p == "t" } {
	   # there was at least one expired ad
	   append body "\n\nNote:  you can revive an expired ad by going to the edit URL (above)
and changing the expiration date."
       }
       append body $generic_postamble
       if [catch { [ns_sendmail $email [gc_system_owner] $subject_line $body] } errmsg] {
	   ns_log Notice "error sending gc_owner_spam to \"$email\""
       }
   }

   ns_log Notice "finished gc_owner_spam at [ns_localsqltimestamp]"

}

# AOLserver stupidly does not source private Tcl after shared Tcl
# probably fixed in 2.3 released

ns_share -init {set gc_spam_scheduled_p 0} gc_spam_scheduled_p

if { !$gc_spam_scheduled_p && ![philg_development_p]} {
    ns_log Notice "scheduling classified ad spam"
    set gc_spam_scheduled_p 1
    if [ad_parameter ProvideEmailAlerts gc 1] { 
	# 5:10 am every day
	ns_schedule_daily 5 10 gc_spam_daily

	# we schedule this at 6:10 am twice because
	# the AOLserver API isn't powerful enough 
	# to say "monday AND thursday"
	ns_schedule_weekly 1 6 10 gc_spam_monthu
	ns_schedule_weekly 4 6 10 gc_spam_monthu
    
	# 7:10 am on Sundays
	ns_schedule_weekly 1 7 10 gc_spam_weekly
    }
    if [ad_parameter NagAdOwners gc 1] {
	# 7:10 am on Wednesdays
	ns_schedule_weekly 3 7 10 gc_ad_owner_spam
    }
}

proc gc_submenu {{domain ""}} {
    if {$domain == ""} {
	return ""
    } else {
        set row_exists_p [db_0or1row domain_id_get "select domain_id from ad_domains where domain = :domain"]
	db_release_unused_handles
        if { $row_exists_p == "" } {
            return ""
        }
	set return_string ""
	upvar auction_p auction_p
	append return_string "
	<form name=jobs_submenu ACTION=/redir>
	<select name=\"url\" onchange=\"go_to_url(this.options\[this.selectedIndex\].value)\">
	<OPTION VALUE=\"/gc/domain-top.tcl?domain_id=[ns_urlencode $domain_id]\">Jobs Options
	<OPTION VALUE=\"/gc/place-ad.tcl?domain_id=[ns_urlencode $domain_id]\">Place An Ad
	<OPTION VALUE=\"/gc/edit-ad.tcl?domain_id=[ns_urlencode $domain_id]\">Edit Old Ad
	<OPTION VALUE=\"/gc/add-alert.tcl?domain_id=[ns_urlencode $domain_id]\">Add/Edit Alert\n"

	if { [info exists auction_p] && $auction_p == "t" } {
	    append return_string "<OPTION VALUE=\"/gc/auction-hot.tcl?domain_id=[ns_urlencode $domain_id]\">Hot Auctions\n"
	}

	set headers [ns_conn headers]
	set cookie [ns_set get $headers Cookie]

	# parse out the second_to_last_visit date from the cookie
	if { [regexp {~second_to_last-([^;]+)} $cookie match second_to_last_visit] } {
	    append return_string " <OPTION VALUE=\"/gc/new-since-last-visit.tcl?domain_id=[ns_urlencode $domain_id]\">Ads Since Last Visit\n"
	}
	append return_string "</select>
	<noscript><input type=\"Submit\" value=\"GO\"></noscript>
	</form>\n"

	return $return_string
    }
}

proc gc_search_result_string {} {
    return "Job listings"
}

##################################################################
#
# interface to the ad-new-stuff.tcl system

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [lsearch -glob $ad_new_stuff_module_list "[gc_system_name]*"] == -1 } {
    lappend ad_new_stuff_module_list [list [gc_system_name] gc_new_stuff]
}

proc gc_new_stuff {since_when only_from_new_users_p purpose} {
    if { $only_from_new_users_p == "t" } {
	set query {
	    select ca.domain_id, ad.domain, count(*) as n_ads
	    from classified_ads ca, ad_domains ad, users_new
	    where posted > :since_when
	    and ca.user_id = users_new.user_id
	    and ad.domain_id = ca.domain_id
	    group by ca.domain_id, ad.domain
	}
    } else {
	set query {
	    select ca.domain_id, ad.domain, count(*) as n_ads
	    from classified_ads ca, ad_domains ad
	    where posted > :since_when
	    and ad.domain_id = ca.domain_id
	    group by ca.domain_id, ad.domain
	}
    }
    set result_items ""
    set url_stub [ad_parameter PartialUrlStub gc "/gc/"]
    db_foreach new_stuff_show $query {	
	switch $purpose {
	    web_display {
		append result_items "<li><a href=\"${url_stub}domain-top?[export_url_vars domain_id]\">$domain</a> ($n_ads new ads)\n"
	    }
	    site_admin { 
		append result_items "<li><a href=\"/admin/gc/domain-top?[export_url_vars domain_id]\">$domain</a> ($n_ads new ads)\n"
	    }
	    email_summary {
		append result_items "$domain classifieds : $n_ads new ads
-- [ad_url]${url_stub}domain-top.tcl?[export_url_vars domain_id]
"
            }
	}
    }
    # we have the result_items or not
    if { $purpose == "email_summary" } {
	return $result_items
    } elseif { ![empty_string_p $result_items] } {
	return "<ul>\n\n$result_items\n</ul>\n"
    } else {
	return ""
    }
}

##################################################################
#
# interface to the ad-user-contributions-summary.tcl system
#

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Classified Ads" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Classified Ads" gc_user_contributions 0]
}

proc_doc gc_user_contributions {user_id purpose} {Returns list items, one for each classified posting} {
    # we query out both the current and audit rows at once (so that we get a complete
    # chronology).  For an ad that is current but has an audit row as well, we'll 
    # get the current one first

    set sql {
	select classified_ad_id, posted, expired_p(expires) as expired_p, one_line, 'f' as audit_row_p
	from classified_ads 
	where user_id = :user_id
	union
	select classified_ad_id, posted, 'f' as expired_p, one_line, 't' as audit_row_p
	from classified_ads_audit
	where user_id = :user_id
	order by classified_ad_id, audit_row_p
    }
    set classified_items ""
    set last_id ""
    db_foreach contributions_list $sql {	
	if { $classified_ad_id == $last_id } {
	    # this is an audit row for a current ad; skip printing it
	    continue
	}
	set suffix ""
	if {$expired_p == "t"} {
	    set suffix "<font color=red>expired</font>\n"
	}
	if {$audit_row_p == "t" } {
	    set suffix "<font color=red>deleted</font>\n"
	    set target_url "view-ad-history.tcl"
	} else {
	    # regular ad
	    set target_url "view-one.tcl"
	    if { $purpose == "site_admin" && $expired_p != "t" } {
		append suffix "\[<a target=another_window href=\"/admin/gc/edit-ad?classified_ad_id=$classified_ad_id\">Edit</a> |
<a target=another_window href=\"/admin/gc/delete-ad?classified_ad_id=$classified_ad_id\">Delete</a> \]\n"
	    }
	}
	append classified_items "<li>[util_AnsiDatetoPrettyDate $posted]: <A HREF=\"/gc/$target_url?classified_ad_id=$classified_ad_id\">$one_line</a> $suffix\n"
	set last_id $classified_ad_id
    }

    if [empty_string_p $classified_items] {
	return [list]
    } else {
	return [list 0 "Classified Ads" "<ul>\n\n$classified_items\n\n</ul>\n"]
    }
}

proc_doc gc_maybe_set_domain_id {} {For pages to which users have bookmarks with the old 'domain' primary key, derive domain_id from the domain variable set in the form.} {
    uplevel {
        if { ![info exists domain_id] && [info exists domain]} {
            set domain_id [db_string domain_id_get {
		select domain_id from ad_domains
		where domain = :domain
	    } -default ""]
	    db_release_unused_handles
	}
    }
}


proc_doc gc_shouting_p {s} {
    Returns 1 if string s contains too many uppercase characters
    or exclamation marks, so we consider it as SHOUTING!!!!!!!!!!!
} {
    set shouting 0
    for {set i 0} {$i<[string length $s]} {incr i} {
	if { [regexp {[A-Z!]} [string index $s $i]] } {
	    incr shouting
	} else {
	    incr shouting -1
	}
    }
    # If the number of shouting characters exceeds the number of
    # non-shouting characters by more than 3, we consider the
    # string as shouting.
    expr $shouting>3
}


