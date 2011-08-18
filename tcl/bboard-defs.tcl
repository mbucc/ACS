# $Id: bboard-defs.tcl,v 3.2.2.3 2000/05/17 10:02:14 carsten Exp $
#
# bboard-defs.tcl
#
# by philg@mit.edu originally sometime in the mid-1990s (1996?)
# 

util_report_library_entry


# Tcl procedures definitions for the discussion forum system,
# generally parked in /bboard

proc bboard_partial_url_stub {} {
    return [ad_parameter PartialUrlStub bboard]
}

proc bboard_hardwired_url_stub {} {
    return "[ad_url][bboard_partial_url_stub]"
}


proc bboard_system_url {} {
    return "[ad_url][bboard_partial_url_stub]"
}

proc bboard_system_name {} {
    set custom_name [ad_parameter SystemName bboard]
    if ![empty_string_p $custom_name] {
	return $custom_name 
    } else {
	return "[ad_parameter SystemName] Discussion Forums"
    }
}

proc_doc bboard_file_uploading_enabled_p {} "We use this to determine whether or not any file uploading is possible.  Then we check bboard_topics for info on a specific forum." {
    return [ad_parameter FileUploadingEnabledP bboard 0]
}

# The path where we store the images. Note that 
# this path does *not* contain a trailing "/"
proc bboard_file_path {} {
    return [ad_parameter FilePath bboard]
}

proc bboard_generate_upload_filename {msg_id upload_id client_filename} {
    # Get the suffix
    set suffix [file extension $client_filename]
    append filename $msg_id "-" $upload_id $suffix
    return $filename
}

# an email address; the discussion forums might
# be owned by someone other than the rest of the system

proc bboard_system_owner {} {
    set custom_owner [ad_parameter SystemOwner bboard]
    if ![empty_string_p $custom_owner] {
	return $custom_owner
    } else {
	return [ad_system_owner]
    }
}

# an email address

proc bboard_host_administrator {} {
    set custom_host_admin [ad_parameter HostAdministrator bboard]
    if ![empty_string_p $custom_host_admin] {
	return $custom_host_admin
    } else {
	return [ad_host_administrator]
    }
}

# Who to send email as. Will receive lots of error messages for bad
# user email addresses.
proc bboard_sender_email {} {
    return [ad_parameter SenderEmail bboard]
}

# change this to return 0 if there is no PLS Blade; 1 if there is
# we set this to 1 even though we don't have a full-text indexer;
# we're doing exhaustive sequential searches via bboard_contains

proc bboard_pls_blade_installed_p {} {
    return [ad_parameter ProvideLocalSearchP bboard]
}

# for the interest level system; anything below this threshold
# is considered uninteresting

proc bboard_interest_level_threshold {} {
    return [ad_parameter InterestLevelThreshold bboard]
}

# change this to return 0 if random users can't add topics

proc bboard_users_can_add_topics_p {} {
    return [ad_parameter UserCanAddTopicsP bboard]
}

proc bboard_raw_backlink {topic_id topic presentation_type {include_hostname_p 1}} {
    if { $presentation_type == "threads" } {
	set raw_backlink "main-frame.tcl?[export_url_vars topic_id topic]"
    } elseif { $presentation_type == "usgeospatial" } {
	set raw_backlink "usgeospatial.tcl?[export_url_vars topic_id topic]"
    } else {
	set raw_backlink "q-and-a.tcl?[export_url_vars topic_id topic]"
    }
    if $include_hostname_p {
	return "[bboard_hardwired_url_stub]$raw_backlink"
    } else {
	return $raw_backlink
    }
}

proc bboard_msg_url { presentation_type msg_id topic_id {topic ""}} {
    if { $presentation_type == "q_and_a" } {
	return "q-and-a-fetch-msg.tcl?[export_url_vars msg_id topic_id topic]"
    } elseif { $presentation_type == "ed_com" } {
	return "ed-com-msg.tcl?[export_url_vars msg_id topic_id topic]"
    } elseif { $presentation_type == "usgeospatial" } {
	return "usgeospatial-fetch-msg.tcl?[export_url_vars msg_id topic_id topic]"
    }  else {
	# this is a frames (bleah) board
	return "main-frame.tcl?[export_url_vars topic_id topic]&feature_msg_id=$msg_id&start_msg_id=$msg_id"
    }
}

proc bboard_complete_backlink {topic_id topic presentation_type {include_partial_url_stub 0}} {
    if $include_partial_url_stub {
	set directory_stub [bboard_partial_url_stub]
    } else {
	set directory_stub ""
    }
    if { $presentation_type == "ed_com" } {
	set complete_backlink "<a href=\"${directory_stub}q-and-a.tcl?[export_url_vars topic_id topic]\">$topic forum</a>"
    } elseif { $presentation_type == "usgeospatial"} {
	set complete_backlink "<a href=\"${directory_stub}usgeospatial.tcl?[export_url_vars topic_id topic]\">$topic forum</a>"
    } elseif { $presentation_type == "threads"} {
	set complete_backlink "<a href=\"${directory_stub}main-frame.tcl?[export_url_vars topic_id topic]\">$topic</a>"
    } else  { 
	set complete_backlink "<a href=\"${directory_stub}q-and-a.tcl?[export_url_vars topic_id topic]\">$topic Q&A forum</a>"

    } 
    return $complete_backlink
}

proc bboard_header {title} {
    return "<html>
<head>
<title>$title</title>
<head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "white"]>
"
}

proc bboard_footer {} {
    uplevel {
	global sidegraphic_displayed_p
	if [info exists maintainer_email] {
	    # we're looking at a particular forum
	    set signature_address $maintainer_email
	} else {
	    set signature_address [bboard_system_owner]
	}
	if { [info exists sidegraphic_displayed_p] && $sidegraphic_displayed_p } {
	    # we put in a BR CLEAR=RIGHT so that the signature will clear any side graphic
	    # from the ad-sidegraphic.tcl package
	    set extra_br "<br clear=right>"
	} else {
	    set extra_br ""
	}
	return "
$extra_br
<hr>
<a href=\"mailto:$signature_address\"><address>$signature_address</address></a>
</body>
</html>
"
    } 
}

# Verify that the user is authorized to see this topic.
# 
# Assumes topic_id or topic is set to some value
# Returns -1 if user is not authorized to view the page
# Returns 1 on if user is OK to view the page
#
#
proc bboard_get_topic_info { } {
    uplevel { 
	if {!([info exists topic_id] && ![catch {set selection [ns_db 1row $db "select t.*,  u.email as maintainer_email, u.first_names || ' ' || u.last_name as maintainer_name, primary_maintainer_id
from bboard_topics t, users u
where topic_id=$topic_id
and t.primary_maintainer_id = u.user_id"]} errmsg])
	    && !([info exists topic] && ![catch {set selection [ns_db 1row $db "select t.*, u.email as maintainer_email, u.first_names || ' ' || u.last_name as maintainer_name, primary_maintainer_id
from bboard_topics t, users u
where topic = '$QQtopic'
and t.primary_maintainer_id = u.user_id"]} errmsg]) } {
	    bboard_return_cannot_find_topic_page
	    return -1
        }
	set_variables_after_query
	set user_id [ad_verify_and_get_user_id]
	# Check read-access of this topic
	if {[string compare $read_access "any"] == 0} {
	   # Any user can view this topic
	   return 1
       } elseif {[string compare $read_access "public"] == 0} {
	   # "public" means user must be logged in to read this topic
	   if {$user_id == 0} { 
	       ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_hardwired_url_stub]admin-home.tcl?[export_url_vars topic_id]"]
	       return -1
	   } else {
	       return 1
	   }
       } elseif {[string compare $read_access "group"] == 0} {
	   # "group" means the user must belong to one of the topic's groups.
           # branimir 2000-02-04
	   # Check if user belongs to any of topic's groups in adminstration_info
	   if {[ad_permission_p $db bboard $topic_id "" $user_id]} {
	       ns_db flush $db
	       return 1
	   } else {
	       # Well, the user isn't in any of the topic's groups. But.. 
	       # If they are site admin group member, let's let them in anyway. 
	       # default to group is private (read_access = group)
	       if {[ad_administration_group_member $db "site_wide" "" $user_id]} {
		   # user is site admin, let them look at the bboard
		   return 1
	       } else {
		   ns_return 200 text/html "[bboard_header "Unauthorized"]
   <h2>Unauthorized</h2>
   <hr>

   You are either not logged into <A href=\"[ad_url]\">[ad_system_name]</a>
   or not authorized to view the $topic forum.

   [bboard_footer]"
		  return -1
	     }
	 }
     }
   }
}



# Verify if current user is allowed to view this topic. 
# Returns 0 if user is not authorized, and sends appropriate error message page
# or redirect to client.
proc bboard_user_has_view_authorization {} {
    uplevel {
	set user_id [ad_verify_and_get_user_id]
	# Check to see if read access on this topic matches with user's group memberships

	set read_access [database_to_tcl_string $db "select read_access from bboard_topics where topic_id = $topic_id"]
	# Anyone can read
    }
    ## +++ NOT FINISHED YET +++
}




# +++ THIS MUST BE DEAD CODE, it refers to bboard_topics.user_password, which looks 
# like it has not existed for awhile -- hqm [9/16/1999]
proc bboard_topic_user_password_p_internal {db topic} {
    set selection [ns_db 0or1row $db "select unique user_password from bboard_topics where topic = '[DoubleApos $topic]'"]
    if { $selection == "" } {
	# couldn't find the topic, they'll err out high up the chain
	return 0
    } else {
	set user_password [ns_set value $selection 0]
	if { $user_password == "" } {
	    return 0
	} else {
	    return 1
	}
    }
}

# ++++++++++++++++

proc bboard_compute_cookie_name {topic {admin 0}} {
    # strip out everything that wouldn't go well in the headers
    regsub -all { } $topic {_} first_try
    regsub -all {=} $first_try {_} second_try
    regsub -all {;} $second_try {_} third_try
    # we need to set it up so that the regular cookie is 
    # not a substring of the admin cookie (otherwise
    # our caveman cookie checking code gets confused when
    # the administrator tries to post)
    if { $admin == 1 } {
	return "Admin$third_try"
    } else {
	return "User$third_try"
    }
}

proc bboard_compute_cookie {topic {admin 0}} {
    # this will only use the first 8 chars of the topic, but that's OK
    if { $admin == 1 } {
	set key "a$topic"
    } else {
	set key $topic
    }
    set day_of_month [lindex [ns_localtime] 3]
    set salt $day_of_month
    set raw_result [ns_crypt $key $salt]
    set minus_salt [string range $raw_result 2 [string length $raw_result]]
    # strip out chars that won't work on header line
    regsub -all {=} $minus_salt "" first_try
    regsub -all {;} $first_try "" second_try
    regsub -all { } $second_try "" third_try
    return $third_try
}

proc bboard_check_cookie {topic {admin 0}} {
    set headers [ns_conn headers]
    set cookie [ns_set get $headers Cookie]
    # we look for the cookie name corresponding to this topic
    # we can't do the obvious thing and use regexp because
    # users can include things like "?" in their topic names
    # and those are magic Tcl regexp chars
    set cookie_name [bboard_compute_cookie_name $topic $admin]
    set pos [string last $cookie_name $cookie]
    if { $pos == -1 } {
	# there wasn't a cookie header or it didn't contain a relevant
	# name
	return 0
    } else {
	# strip off the cookie name
	set rest_of_cookie [string range $cookie [expr $pos + [string length $cookie_name]] [string length $cookie]]
	if { [regexp {[ ]*=[ ]*([^; ]+).*} $rest_of_cookie match just_the_value] } {
	    set what_we_would_like_to_see [bboard_compute_cookie $topic $admin]
	    if { $just_the_value == $what_we_would_like_to_see } {
#		ns_log Notice "Cookie matched! : $cookie"
		# we found a legit value
		return 1
	    } else {
		# we got the value out but it didn't work (maybe because it 
		# was too old)
		ns_log Notice "Cookie was too old : $cookie (we wanted $what_we_would_like_to_see but got $just_the_value); rest_of_cookie:  $rest_of_cookie "
		return 0
	    }
	} else {
	    ns_log Notice "Found a cookie but couldn't get the value out: $cookie"
	    return 0
	}
    }
}

# useful for sending email to people telling them where to come back

proc bboard_url_stub {} {
    regexp {(.*/)[^/]*$} [ns_conn url] match just_the_dir

    append url_stub [ns_conn location] $just_the_dir 

    return $url_stub

}

# for subject listings

proc bboard_compute_msg_level { sort_key } {

    set period_pos [string first "." $sort_key]

    if { $period_pos == -1 } {

	# no period, primary level

	return 0

    } else {

	set n_more_levels [expr ([string length $sort_key] - ($period_pos + 1))/2]

	return $n_more_levels

    }


}

proc bboard_db_gethandle {} {
    if [catch {set db [ns_db gethandle]} errmsg] {
    # something wrong with the NaviServer/db connection
	ad_notify_host_administrator "please fix [ns_conn location]" "please fix [ns_conn location] so that it can talk to Oracle

Thanks,

The Ghost of the AOLserver

Note:  this message was automatically sent by a Tcl CATCH statement running
inside [ns_conn location]
"
        return ""
    } else {
        return $db
    }
}

proc bboard_return_cannot_find_topic_page {} {
    set_form_variables
    if { [info exists topic] } {
	set topic_blurb $topic
    } else {
	set topic_blurb "No Topic Variable Supplied"
    }
    ns_return 200 text/html "[bboard_header "Cannot Find Topic"]

<h2>Cannot Find Topic</h2>
<hr>

This page was called with a topic variable of \"$topic_blurb\".  There is no
bboard in the database with that topic name.  Either you have been
manually adjusting the URL (perhaps by cutting and pasting) or something
is seriously wrong with the [bboard_system_name] system.

<p>

You can probably find the page that you need by starting from the 
<a href=\"index.tcl\" target=\"_top\">[bboard_system_name] home page</a>.

<hr>
<a href=\"mailto:[bboard_system_owner]\">[bboard_system_owner]</a>
</body>
</html>"
}

proc bboard_return_error_page {} {
    ns_return 500 text/html "<html>
<head>
<title>Server is Having Trouble</title>
</head>

<body bgcolor=#ffffff text=#000000>
<h2>Server is Having Trouble</h2>
<hr>

Our server can't connect to the relational database right now.  This
is presumably because of a system administration problem.  You can <a
href=\"mailto:[bboard_host_administrator]\">send the administrator
email at [bboard_host_administrator]</a> and ask him/her to fix 
[ns_conn location] because you value this service.

<hr>
<a href=\"mailto:[bboard_system_owner]\">[bboard_system_owner]</a>
</body>
</html>"
}

# all the stuff for email notifications have to go here

proc bboard_spam_daily {} {
    bboard_spam "daily"
}

proc bboard_spam_monthu {} {
    bboard_spam "Monday/Thursday"
}

proc bboard_spam_weekly {} {
    bboard_spam "weekly"
}

# we must check or each TclInit will cause these to be scheduled again!

ns_share -init {set bboard_spam_scheduled 0} bboard_spam_scheduled


if { !$bboard_spam_scheduled && ![philg_development_p]} {

    set bboard_spam_scheduled 1

    ns_log Notice "Scheduling bboard spam with ns_schedule..."
    # we schedule this at 3:30 am with the THREAD option
    # because it isn't going to return any time soon
    # **** actually we take out the thread option because
    # Doug McKee says it might not work
    ns_schedule_daily  3 30 bboard_spam_daily

    # we schedule this at 4:30 am twice because 
    # the AOLServer API isn't powerful enough to 
    # say "monday AND thursday" 
    ns_schedule_weekly  1 4 30 bboard_spam_monthu
    ns_schedule_weekly  4 4 30 bboard_spam_monthu

    # we schedule this at 5:30 am on Sunday
    ns_schedule_weekly  0 5 30 bboard_spam_weekly

} else {
    ns_log Notice "bboard spam already scheduled, doing nothing"
}

proc ugly_frequency {pretty_frequency} {
    if { $pretty_frequency == "Monday/Thursday" } {
	return "monthu"
    } else {
	return $pretty_frequency
    }
}

proc bboard_spam {frequency} {
    set ugly_frequency [ugly_frequency $frequency]
    # ***** subquery was [philg_server_default_pool]
    set db_pools [ns_db gethandle subquery 2]
    set db [lindex $db_pools 0]
    set db_sub [lindex $db_pools 1]
    # we could just update bboard_email_alerts_updates
    # right now but we don't because we might get interrupted
    set start_time [database_to_tcl_string $db "select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') from dual"]
    ns_log Notice "Started doing $frequency bboard email alerts at $start_time"

    # we want the OID to give the user the option to instantly disable the alert
    set selection [ns_db select $db "select bea.*,bea.rowid, users_alertable.email, bboard_topics.topic
from bboard_email_alerts bea,  users_alertable, bboard_topics
where valid_p <> 'f'
and bea.user_id = users_alertable.user_id
and bboard_topics.topic_id = bea.topic_id
and frequency = '$frequency'"]
    set mail_counter 0

    while {[ns_db getrow $db $selection]} {
    # this is the outer loop where each row is an alert for one email address
	set_variables_after_query
	ns_log Notice "checking $rowid alert for $email ... ($topic,$keywords)"
	set msg_body ""
	if { $keywords != "" && [bboard_pls_blade_installed_p] == 0 } {
	    # this is trouble, the user spec'd keywords but the PLS blade
	    # isn't installed, so we'll have to do this very stupidly
	    set keyword_list [split $keywords " "]
	    set keyword_clauses [list]
	    foreach keyword $keyword_list {
		lappend keyword_clauses "message like '%[DoubleApos $keyword]%'"
	    }
	    if { [llength $keyword_clauses] == 0 } {
		set final_keyword_clause ""
	    } else {
		set final_keyword_clause "and ([join $keyword_clauses " OR "])"
	    }
	    set sql "select * from bboard 
where topic_id = $topic_id
$final_keyword_clause
and posting_time > (select unique $ugly_frequency from bboard_email_alerts_updates)
order by posting_time"
	} elseif { $keywords == "" } {
	    # user wants everything
	    set sql "select bboard.*, first_names || ' ' || last_name as name,
email from bboard, users 
where topic_id = $topic_id
and posting_time > (select unique $ugly_frequency from bboard_email_alerts_updates)
and users.user_id = bboard.user_id
order by posting_time"
        } else {
	    # user spec'd keywords 
	    regsub -all {,+} $keywords " " keywords
	    set sql "select bboard.* , first_names || ' ' || last_name as name,
email from bboard, users 
where topic_id = $topic_id
and bboard.user_id = users.user_id
and posting_time > (select unique $ugly_frequency from bboard_email_alerts_updates)
and bboard_contains(email, first_names || last_name, one_line, message,'[DoubleApos $keywords]') > 0
order by posting_time"
        }
	# at this point, SQL is set or we've skipped to the next loop iteration
	if [catch {set sub_selection [ns_db select $db_sub $sql]} errmsg] {
	    # probably ConText coughed up an error
	    ns_log Notice "error trying to send an alert:  $errmsg"
	    # just to the next loop iteration (i.e., the next alert)
	    continue
	}
	while {[ns_db getrow $db_sub $sub_selection]} {
	    # this is the inner loop where each row is a bboard posting
	    set from_email [ns_set get $sub_selection email]
	    set from_name [ns_set get $sub_selection name]
	    set one_line [ns_set get $sub_selection one_line]
	    set message [ns_set get $sub_selection message]
	    set posting_time [ns_set get $sub_selection posting_time]
	    append msg_body "From: $from_name <$from_email>
Subject: $one_line
Date: $posting_time

[ns_striphtml $message]

--------------
"

	}
	if { $msg_body != "" } {
	    # we have something to send
	    set sub_selection [ns_db 1row $db_sub "select first_names || ' ' || last_name as maintainer_name, email as maintainer_email, presentation_type 
from bboard_topics, users
where topic_id = $topic_id and
bboard_topics.primary_maintainer_id = users.user_id"]
            set_variables_after_subquery
	    append msg_body "
The maintainer email is $maintainer_email.
This message was sent because you asked the [bboard_system_name] system
to alert you via email of new postings in the $topic forum, 
to which you can return at

[bboard_raw_backlink $topic_id $topic $presentation_type]

If you are annoyed by this message then just enter the following URL
into a browser and you'll disable the alert that generated this mail:

[bboard_hardwired_url_stub]alert-disable.tcl?rowid=$rowid

"
            # we don't want a bad email address terminating the program
            if [catch { ns_sendmail $email $maintainer_email "$topic forum $frequency summary" $msg_body } errmsg] {
		# failed
		ns_log Notice "Failed to send bboard alert to $email:  $errmsg"
	    } else {
		# succeeded
		ns_log Notice "Send bboard alert to $email."
		incr mail_counter
	    }
	}
    }
    # we've finished looping through the alerts 
    ns_db dml $db "update bboard_email_alerts_updates 
set $ugly_frequency = to_date('$start_time','YYYY-MM-DD HH24:MI:SS'),
$ugly_frequency\_total = $ugly_frequency\_total + $mail_counter"
    set stop_time [ns_localsqltimestamp]
    ns_log Notice "Finished doing $frequency bboard email alerts at $stop_time"

}

###
#  Helper functions for insert-msg.tcl
#


proc increment_char_digit {old_char} {

    # get ASCII decimal code for a character
    scan $old_char "%c" code
    
    if { $code == 57 } {

	# skip from 9 to A

	set new_code 65
	set carry 0

    } elseif { $code == 90 } {

	# skip from Z to a

	set new_code 97
	set carry 0

    } elseif { $code == 122 } {

	set new_code 48
	set carry 1

    } else { 

	set new_code [expr $code + 1]
	set carry 0

    }

    return [list [format "%c" $new_code] $carry]

}

# takes 000000 and gives back 000001

proc increment_six_char_digits {old_six_digits {index 5}} {

    set char [string index $old_six_digits $index]

    set digit_result [increment_char_digit $char]
    set new_digit [lindex $digit_result 0]
    set carry [lindex $digit_result 1]

    if { $carry == 0 } {

	append new_id [string range $old_six_digits 0 [expr $index - 1]] $new_digit [string range $old_six_digits [expr $index + 1] 5]

	return $new_id

    } elseif { $index == 0 } {

	# we've got a carry out of our add to the most significant digit

	error "Tried to increment $old_six_digits but have run out of room"

    } else {

	# we've got a carry out but we're not at the end of our rope

	append intermediate_result [string range $old_six_digits 0 [expr $index - 1]] $new_digit [string range $old_six_digits [expr $index + 1] 5]

	# we recurse and decrement the index so we're working 
	# on a more significant digit
	
	return [increment_six_char_digits $intermediate_result [expr $index - 1]]

    }
}

proc increment_two_char_digits {last_two_chars} {

    set msd [string index $last_two_chars 0]
    set lsd [string index $last_two_chars 1]
	
    set lsd_result [increment_char_digit $lsd]
    set new_lsd [lindex $lsd_result 0]
    set carry [lindex $lsd_result 1]

    if { $carry == 0 } {

	set new_msd $msd

    } else {

	set msd_result [increment_char_digit $msd]
	set new_msd [lindex $msd_result 0]
	set msd_carry [lindex $msd_result 1]

	if { $msd_carry != 0 } {

	    error "Tried to increment $last_two_chars but have run out of room"

	}

    }

    return "$new_msd$new_lsd"

}

proc new_sort_key_form {old_sort_key} {

    if { [string first "." $old_sort_key] == -1 } {

	# no period found, so old sort key is just "00z3A7", a msg_id

	# form for next level is "<msg_id>.<char><char>"

	return "$old_sort_key.\__"

    } else {

	# period found, so old sort key is of form "317.CCDDKK"

	return "$old_sort_key\__"

    }

}

proc new_sort_key {refers_to_key last_key} {

    if { $last_key == "" } {

	# this is the first message that refers to the previous one, so we
	# just add ".00" or "00"

	if { [string first "." $refers_to_key] == -1 } {

	    # no period found, so refers_to_key is just "00007Z", a msg_id
	    # (i.e., the thing we're referring to is top level)

	    append new_key $refers_to_key ".00"

	} else {

	    # period found, so last_key is of form "00007Z.CCDDKK"

	    append new_key $refers_to_key "00"

	}

	return $new_key

    } else {

	# we're not the first response to $refers_to
	# last key cannot be just a msg id, but must have two chars at the end
	# 00 through zz

	regexp {(.*)(..)$} $last_key match front_part last_two_chars

	return "$front_part[increment_two_char_digits $last_two_chars]"

    }


}

proc bboard_convert_plaintext_to_html {raw_string} {
    if { [regexp -nocase {<p>} $raw_string] || [regexp -nocase {<br>} $raw_string] } {
	# user was already trying to do this as HTML
	return $raw_string
    } else {
	regsub -all "\015\012\015\012" $raw_string "\n\n<p>\n\n" plus_para_tags
	return $plus_para_tags
    }

}

# recursive procedure that keeps building a list of people to whom
# notifications have been sent (so that duplicates aren't sent to
# people who appear in the same thread twice)

proc notify_if_requested {db new_msg_id notify_msg_id from subject_line body already_notified} {

    set selection [ns_db 1row $db "select email,refers_to,notify
 from bboard, users
 where bboard.user_id = users.user_id
 and msg_id = '$notify_msg_id'"]

    set_variables_after_query

    if { $notify == "t" && [lsearch -exact $already_notified $email] == -1 } {
	# user asked to be notified and he has not already been for this posting

	set shut_up_url "[bboard_url_stub]shut-up.tcl?msg_id=$notify_msg_id"

	# we use a Tcl Catch system function
	# in case some loser typed in "dogbreath 78 @ aol.com" 
	# that would cause ns_sendmail to barf up an error
	# this way the recursion proceeds even with one bad email address
	# in the chain

	if ![catch { ns_sendmail $email $from $subject_line "$body

-------------

If you are no longer interested in this thread, simply go to the
following URL and you will no longer get these notifications:

$shut_up_url

-------------

Note:  this message was sent by a robot.

"
       } errmsg] {
	   # no error
	   ns_write "<li>sent a note to $email, to whose message you are responding.\n"
       }

       # mark this address as having already been notified

       lappend already_notified $email

    }

    if { $refers_to != "" } {

	# recurse with all the same args except NOTIFY_MSG_ID

	notify_if_requested $db $new_msg_id $refers_to $from $subject_line $body $already_notified

    }

}

# for flaming postings

proc bboard_pretend_to_be_broken {full_anchor maintainer_email} {
    ReturnHeaders

    ns_write "<html>
<head>
<title>Inserting Message</title>
</head>
<body bgcolor=#ffffff text=#000000>

<h3>Inserting Message</h3>

into the $full_anchor

<hr>

You would think that this operation would be quick and fast,
especially given that the author of this software holds himself out as
an expert in the book <a
href=\"http://photo.net/wtr/dead-trees/\">Database Backed Web
Sites</a>.  And indeed this operation <em>was</em> quick and fast when
the forum was lightly used.  But now with thousands of users and
20,000 old messages in the forum, the limitations of the relational
database management system underneath are beginning to show.

<P>

All of the photo.net collaboration services use the Illustra RDBMS.
This system has kind of a pure university egghead flavor to it and
this means that by default nobody can read from a table while anyone
is writing to it.  Nor can anyone write a new row (message) into a
table while anyone is reading from it.  

<p>

I'm currently porting all of my stuff to a monster HP Unix box at MIT
running the Oracle RDBMS, a system inspired more by the needs of
enormous banks and insurance companies than by university professors
trying to impress their colleagues.  In Oracle, readers never have to
wait for writers or vice versa.  Given that there are sometimes as
many as 100 simultaneous users grabbing stuff from photo.net, this is
likely to be a much better system.  Sadly, though, I haven't finished
porting all of my code to Oracle (because I'm combining the port with the 
construction of Version 0.1 of 
<a href=\"http://photo.net/wtr/software-industry.html\">my grand scheme for reforming the way Web publishing is done</a>).

<P>

Since we're still running off Illustra, you'll very likely have to
wait for awhile and/or get the dreaded \"deadlock\" error message.  If
you get the latter, just leave your browser window sitting for three
minutes and then hit the Reload button to resubmit your posting.

<P>

OK, after all of that blather, we're going to try the insert now...

<p>

"
   ns_sleep 60

   ns_write "<h3>Ouch!!</h3>


Here was the bad news from the database:
<pre>

XS1002:Deadlock: transaction aborted, all commands ignored until end transaction

</pre>

If you see \"deadlock\" above, remember that you can resubmit your
posting in a few minutes and it will probably work fine (when the
server gets totally wedged, I have another AOLserver process beat it
over the head with a (Unix) tire iron; this takes 3 minutes from the time of first wedge). 

<hr>

<a href=\"mailto:$maintainer_email\"><address>$maintainer_email</address></a>
</body>
</html>
"


}

proc bboard_compute_categories_with_count {topic_id} {
    set db [ns_db gethandle subquery]
    set selection [ns_db select $db "select category, count(*) as n_threads
from bboard 
where refers_to is null
and topic_id = $topic_id
and category is not null
and category <> 'Don''t Know'
group by category 
order by 1"]
     set result ""
     while {[ns_db getrow $db $selection]} {
	 set_variables_after_query
	 append result "<li><a href=\"q-and-a-one-category.tcl?[export_url_vars topic_id]&category=[ns_urlencode $category]\">$category</a> ($n_threads)\n"
     }
     ns_db releasehandle $db
     return $result
}

# for admin pages

proc dependent_sort_key_form {old_sort_key} {
    if { [string first "." $old_sort_key] == -1 } {
	# no period found, so old sort key is just "00z3A7", a msg_id
	# form for dependents is "<msg_id>.<zero or more chars>"
	return "$old_sort_key.%"
    } else {
	# period found, so old sort key is of form "317.CCDDKK"
	# we demand at least two chars after the old key ("__")
	# plus zero or more ("%")
	return "$old_sort_key\__%"
    }
}

proc bboard_delete_messages_and_subtrees_where {db where_clause} {
    set sort_keys [database_to_tcl_list $db "select sort_key 
from bboard 
where $where_clause"]
    foreach sort_key $sort_keys {
	# this should kill off an individual message or a whole
	# subtree if there are dependents
	ns_db dml $db "delete from bboard where sort_key like '${sort_key}%'"
    }
}


# Verify that user is an admin for a group which is associated with topic_id.
# Returns 1 if true, 0 otherwise.
proc bboard_user_is_admin_for_topic {db user_id topic_id} {
    return [expr [database_to_tcl_string $db "select count(*) 
from bboard_topics
where primary_maintainer_id = $user_id
and topic_id = $topic_id"] || [ad_administration_group_member $db "bboard" $topic_id $user_id]]
}

# Verify if a user is allowed to view this topic.
# Return 1 if allowed, 0 otherwise.
#
# The topic is viewable if:
# - The read_access is 'any' or 'public'.
#   OR
# - The read_access is 'group' and the user is a member of
#   one of the groups that the topic belongs to.
# 
proc bboard_user_can_view_topic_p {db user_id topic_id} {
    set read_access [database_to_tcl_string $db "select read_access from bboard_topics where topic_id = $topic_id"]
    if {[string compare $read_access "any"] == 0 || [string compare $read_access "public"] == 0} {
	return 1
    } else {
	set selection [ns_db 0or1row  $db "select user_id from user_group_map 
	where user_id = $user_id 
	and group_id in (select group_id from bboard_topic_group_map where topic_id = $topic_id)"]
	if { [empty_string_p $selection] } {     
	    return 0
	} else {
	    return 1
	}
    }
}

## 
# Is the current user an authorized admin for this topic?
# assumes $db and $topic_id are defined
# returns -1 on auth failure
proc bboard_admin_authorization {} {
    uplevel {
	set user_id [ad_verify_and_get_user_id]

	if {$user_id == 0} {

	    ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_hardwired_url_stub]admin-home.tcl?[export_url_vars topic_id]"]
	    return -1
	}

	# Check to see if user is an admin in the topic's group.

        if { [bboard_user_is_admin_for_topic $db $user_id $topic_id]== 0 } {
	    
	    ns_return 200 text/html "[bboard_header "Unauthorized"]

	    <h2>Unauthorized</h2>
	    <hr>

	    You are either not logged into <A href=\"[ad_url]\">[ad_system_name]</a>
	    or not authorized to administer the $topic forum.
	    
	    [bboard_footer]"
	    return -1
	} else {
	    return 1
	}
    }
}

# Check if the user has any admin role in any group.
# This is used to screen users who want to create a new topic.
# assumes db is bound
proc bboard_check_any_admin_role {} {
    uplevel {
	set user_id [ad_verify_and_get_user_id]

	if {$user_id == 0} {

	    ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_hardwired_url_stub]admin-home.tcl?[export_url_vars topic_id]"]
	    return
	}

	# Check to see if user is an admin in the topic's group.

	set n_rows [database_to_tcl_string $db "select count(user_id)
	from user_group_map ugm
	where ugm.user_id = $user_id
	and ugm.role = 'administrator'"]
	if { $n_rows <= 0 } {
	    ns_return 200 text/html "[bboard_header "Unauthorized"]

	    <h2>Unauthorized</h2>
	    <hr>

	    You are either not logged into <A href=\"[ad_url]\">[ad_system_name]</a>
	    or not authorized to administer the $topic forum.
	    
	    [bboard_footer]"
	    return -1
	}
    }
}






# stuff just for usgeospatial

proc usgeo_n_spaces {n} {
    set result ""
    for { set i 0} {$i < $n} {incr i} {
	append result "&nbsp;"
    }
    return $result
}

proc bboard_usgeospatial_about_link {db msg_id} {
    set selection [ns_db 0or1row $db "select one_line, zip_code, bboard.fips_county_code, bboard.usps_abbrev, bboard.epa_region, users.user_id as poster_id,  users.first_names || ' ' || users.last_name as name, bboard.tri_id, facility, fips_county_name, rel_search_st.state_name
from bboard, users, rel_search_fac, rel_search_co, rel_search_st
where bboard.user_id = users.user_id
and bboard.tri_id = rel_search_fac.tri_id(+)
and bboard.fips_county_code = rel_search_co.fips_county_code(+)
and bboard.usps_abbrev = rel_search_st.state
and msg_id = '$msg_id'"]
    set_variables_after_query
    if { ![empty_string_p $tri_id] && ![empty_string_p $facility] } {
	# we have a facility
	set about_text $facility
    } elseif { ![empty_string_p $zip_code] } {
	set about_text "Zip Code $zip_code"
    } elseif { ![empty_string_p $fips_county_code] } {
	set about_text "$fips_county_name County"
    } elseif { ![empty_string_p $usps_abbrev] } {
	set about_text "$state_name"
    }
    set about_link "<a href=\"usgeospatial-fetch-msg.tcl?msg_id=$msg_id\">$one_line (about $about_text)</a>"
    return $about_link
}


# on the main page, we list out the forums grouped my
# their moderation policy.  This procedure gives the order
# to search for

proc bboard_moderation_policy_order {} {
    return " \"\" featured moderated unmoderated private"
}

# give the title heading for a given moderation policy

proc bboard_moderation_title {moderation_policy} {
    switch [string tolower $moderation_policy] {
	"featured" {return "Featured Forums"}
	"moderated" {return "[ad_system_name] Moderated Forums"}
	"unmoderated" {return "Unmoderated Forums"}
	"private" {return "Private Forums"}
	default { return "" }
    } 
}


proc bboard_private_error {topic name email} {
    ReturnHeaders
    ns_write "
    [bboard_header "Private discussion group"]
    <h2>$topic</h2>
is a private discussion group in <A HREF=\"index.tcl\">[bboard_system_name]</a> 
<hr>
<p>
You are not permitted to enter this topic because 
it is private. Please contact <A HREF=\"mailto:$email\">$name</a> if you would like join.
[bboard_footer]"
     return
}

# This procedure is used to delete uploaded files.
# It is usually called using ns_atclose so that this is
# executed after the database information has been updated
# To make sure that the transaction has successfully happened,
# we check that the files to delete are no longer in the database

# ** note that this used to take an actual list but we're always
# calling it in an ns_atclose so the list gets expanded

proc bboard_delete_uploaded_files args {
    # Tcl is too stupid to allow N args unless you call them "args"
    set list_of_files $args
    ns_log Error "bboard_delete_uploaded_files asked to delete 
[join $list_of_files "\n"]
\n
"
    # Let's not do more work than we need to do.
    if {[llength $list_of_files] == 0} {
	return
    }
    
    # let's double check to make sure that none are in the database
    set db [ns_db gethandle subquery]
    set count [database_to_tcl_string $db "select count(*) 
from bboard_uploaded_files
where filename_stub IN ('[join [DoubleApos $list_of_files] "','"]')"]

    # If any file is still there, don't do anything
    if {$count > 0} {
	ns_log Error "bboard_delete_uploaded_files asked to delete 
[join $list_of_files "\n"]
but at least one was still on record in the bboard_uploaded_files table."
	return
    }

    foreach file $list_of_files {
	set full_path "[bboard_file_path]$file"
	ns_log Notice "bboard_delete_uploaded_files removing $full_path"
	ns_unlink $full_path
    }
    ns_db releasehandle $db
}

##################################################################
#
# interface to the ad-new-stuff.tcl system

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [lsearch -glob $ad_new_stuff_module_list "Bboard*"] == -1 } {
    lappend ad_new_stuff_module_list [list "Bboard" bboard_new_stuff]
}

proc bboard_new_stuff {db since_when only_from_new_users_p purpose} {
    if { $only_from_new_users_p == "t" } {
	set query "select bt.topic, bt.presentation_type, count(*) as n_messages
from bboard, bboard_topics bt, users_new
where posting_time > '$since_when'
and bboard.user_id = users_new.user_id
and bboard.topic_id = bt.topic_id
group by bt.topic, bt.presentation_type"
    } else {
	set query "select bt.topic_id, bt.topic, bt.presentation_type, count(*) as n_messages
from bboard, bboard_topics bt
where posting_time > '$since_when'
and bboard.topic_id = bt.topic_id
group by bt.topic_id, bt.topic,  bt.presentation_type"
    }
    set result_items ""
    set selection [ns_db select $db $query]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	switch $purpose {
	    web_display {
		append result_items "<li>[bboard_complete_backlink $topic_id $topic $presentation_type 1] ($n_messages new messages)\n" }
	    site_admin { 
		append result_items "<li>[bboard_complete_backlink $topic_id $topic $presentation_type 1] ($n_messages new messages)\n\n"
	    }
	    email_summary {
		append result_items "$topic forum : $n_messages new messages
  -- [bboard_raw_backlink $topic_id $topic $presentation_type 1]
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

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "/bboard postings" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "/bboard postings" bboard_user_contributions 0]
}

proc_doc bboard_user_contributions {db user_id purpose} {Returns list items, one for each bboard posting} {
    if { $purpose == "site_admin" } {
	set restriction_clause ""
    } else {
	set restriction_clause "\nand (bboard_topics.read_access in ('any', 'public'))\n"
    }
    set selection [ns_db select $db "select one_line, msg_id,  posting_time, sort_key, bboard_topics.topic, bboard_topics.topic_id, presentation_type 
from bboard, bboard_topics 
where bboard.user_id = $user_id
and bboard.topic_id = bboard_topics.topic_id $restriction_clause
order by posting_time desc"]

    set bboard_items ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if { [string first "." $sort_key] == -1 } {
	    # there is no period in the sort key so this is the start of a thread
	    set thread_start_msg_id $sort_key
	} else {
	    # strip off the stuff before the period
	    regexp {(.*)\..*} $sort_key match thread_start_msg_id
	}
	append bboard_items "<li>[util_AnsiDatetoPrettyDate $posting_time]: <a href=\"/bboard/[bboard_msg_url $presentation_type $thread_start_msg_id $topic_id $topic]\">$one_line</a>\n"
    }
    if [empty_string_p $bboard_items] {
	return [list]
    } else {
	return [list 0 "/bboard postings" "<ul>\n\n$bboard_items\n\n</ul>"]
    }
}

# stuff added for Sharenet (urgent messages)
# modified by Branimir (bd) to comply with Henry's topic_id stuff

proc_doc bboard_urgent_message_items {db {archived_p "f"} {show_min 0} {show_max 50000} {skip_first 0}} "Returns a string of <LI> with hyperlinks to the current bboard items that are marked urgent." {

    if {$archived_p == "t"} {
	set archived_qual "and sign(bboard.posting_time + [ad_parameter DaysConsideredUrgent bboard] - sysdate) < 1"
        set sort_key "posting_time desc"
    } else {
	set archived_qual ""
        #set sort_key "urgent_sign desc, answered_p asc, posting_time desc"
        set sort_key "urgent_sign desc, posting_time desc"

    }
 
# (bd Nov 1999) Note to the usage of NVL function on two places below:
# I wanted to get rid of the annoying Oracle error message
# in the log file "Warning of a NULL column in an aggregate function"

    set selection [ns_db select $db "select bboard.msg_id, 
bboard.one_line,  sort_key, bboard.topic_id, bboard_topics.topic, bboard_topics.presentation_type,
users.email, users.first_names || ' ' || last_name as name, users.user_id,
bboard.posting_time, sign(bboard.posting_time + [ad_parameter DaysConsideredUrgent bboard] - sysdate) as urgent_sign,
max(nvl(bboard_new_answers_helper.posting_time, '0001-01-01')) as last_response,
sign(count(nvl(bboard_new_answers_helper.root_msg_id,0))) as answered_p
from bboard, bboard_new_answers_helper, bboard_topics, users
where bboard.user_id = users.user_id
and bboard_new_answers_helper.root_msg_id(+) = bboard.msg_id
and bboard_topics.topic_id = bboard.topic_id
and (bboard_topics.read_access in ('any', 'public'))
and bboard.urgent_p = 't'
$archived_qual
group by bboard.msg_id, bboard.one_line, bboard.topic_id, 
bboard_topics.topic, bboard_topics.presentation_type, sort_key, users.user_id, users.first_names || ' ' || last_name, email, bboard.posting_time
order by $sort_key"]

    # Siemens wants to display, at a minimum, the last 3 urgent

    set urgent_items ""
    set count 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if { [string first "." $sort_key] == -1 } {
	    # there is no period in the sort key so this is the start of a thread
	    set thread_start_msg_id $sort_key
	} else {
	    # strip off the stuff before the period
	    regexp {(.*)\..*} $sort_key match thread_start_msg_id
	}
	if {$count < $show_max && ($urgent_sign == 1 || $archived_p == "t" || $count < $show_min)} {
	    if {$count >= $skip_first} {
	          append urgent_items "<li><a href=\"/bboard/[bboard_msg_url $presentation_type $thread_start_msg_id $topic]\">$one_line</a> <i>(<a href=\"/shared/community-member.tcl?[export_url_vars user_id]\">$name</a> on $posting_time in $topic"
                  if {"$last_response" != "0001-01-01"} {
	         	append urgent_items ", last response on $last_response"
	          }
	    append urgent_items ")</i>\n"
	    }
	} else {
	    break
	}
	incr count
    }
    return $urgent_items
}


proc bboard_one_line_suffix {selection subject_line_suffix} {
   # subject_line_suffix is a list containig any combination of keywords:
   # {name email date}. It controls what information is displayed after the
   # usual one line subject.
   set posting_time [ns_set get $selection posting_time]
   set urgent_p [ns_set get $selection urgent_p]
   set num_responses [ns_set get $selection num_responses]
   set topic_id [ns_set get $selection topic_id]
   set msg_id [ns_set get $selection msg_id]
   # Date of last response:
   set last_response [ns_set get $selection last_response]
   # Author of the current message:
   set poster_id [ns_set get $selection poster_id]
   set name [ns_set get $selection name]
   set email [ns_set get $selection email]
   # The User who is viewing this:
    upvar user_id user_id
   set suffix ""
   foreach column $subject_line_suffix {
	if { $column == "name" && $name != "" } {
	   append suffix " by <a href=\"/shared/community-member.tcl?user_id=$poster_id\">$name</a>"
        }
	if { $column == "email" && $email != "" } {
	   append suffix " ($email)"
        }
	if { $column == "date" && [info exists posting_time] && $posting_time != "" } {
	   append suffix " ($posting_time)"
        }
   }
   if { [ad_parameter UrgentMessageEnabledP "bboard" 0] && [info exists urgent_p] && $urgent_p == "t" } {
       append suffix " <font color=red>urgent!</font> "
       if { $poster_id == $user_id } {
   	  append suffix " <A href=\"msg-urgent-toggle.tcl?[export_url_vars msg_id]&return_url=[ns_urlencode q-and-a.tcl?[export_url_vars topic_id]]\">Make unurgent</a> "
       }
   }
   return $suffix
}


util_report_successful_library_load
