# $Id: insert-msg.tcl,v 3.4.4.3 2000/04/28 15:09:42 carsten Exp $
# Insert a new message into bboard
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_handle_spammers

# bboard_already_notified_p
# Returns 1 if the user is already queued to be emailed. 0 if not.

# "to_email" is the email address of the user receiving the email
# "email_queue" is a list of ns_set id's

# The target email address for the alert is associated with the
# "to" key of each ns_set in $email_queue

# This proc compares "to_email" with all the
# values in the "to" key of each ns_set in email_queue and
# returns 1 if there is a match, or 0 if not

proc bboard_already_notified_p { to_email email_queue } {
    foreach email $email_queue {
	if { [string compare $to_email [ns_set get $email to]] == 0 } {
	    # email matched
	    return 1
	}
    }
    # we've search all the ns_sets and have not found a match
    return 0
}


# Returns ns_set specifying a message to be sent to a user somewhere 
# regarding a new message posting on the bboard.  We enqueue everything
# so that the production thread can release the database handle and not
# bring down the Web server if the mail transfer agent is down.

proc bboard_build_email_queue_entry {to from subject body user_message {extra_headers ""}} {
    set email_ns_set [ns_set create email_queue_entry]
    ns_set put $email_ns_set to $to
    ns_set put $email_ns_set from $from
    ns_set put $email_ns_set subject $subject
    ns_set put $email_ns_set body $body
    ns_set put $email_ns_set user_message $user_message
    if ![empty_string_p $extra_headers] {
	ns_set put $email_ns_set extraheaders $extra_headers
    }
    return $email_ns_set
}

# we use notify_if_requested_build to build up a list
# of emails to be sent to users who previously posted
# a message in this thread

# Returns email queue (list of ns_sets)

proc notify_if_requested_build { db thread_start_msg_id from subject_line body } {
    set email_queue [list]
    set selection [ns_db select $db "select ua.email, ea.rowid
from bboard_thread_email_alerts ea, users_alertable ua
where ea.thread_id = '$thread_start_msg_id'
and ea.user_id = ua.user_id"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	set shut_up_url "[bboard_url_stub]shut-up.tcl?row_id=[ns_urlencode $rowid]"

	set customized_body  "$body
	    
-------------

If you are no longer interested in this thread, simply go to the
following URL and you will no longer get these notifications:

$shut_up_url

-------------

Note:  this message was sent by a robot.

"
	set email_queue_entry [bboard_build_email_queue_entry $email $from $subject_line $customized_body "<li>sent a note to $email, who asked to be notified of responses.\n"]
	lappend email_queue $email_queue_entry
    }
    
    return $email_queue
}

set_the_usual_form_variables

# body, one_line, notify, html_p
# topic_id, topic are hidden vars
# q_and_a_p is an optional variable, if set to "t" then this is from 
# the Q&A forum version
# refers_to is "NEW" or a msg_id (six characters)

# we MAY get an image or other file along with this msg, which means
# we'd get the file name in "upload_file" and can get out the temp file
# with ns_queryget

# we're going to need to subquery for instant keyword matching
# and/or looking around for state and county from tri_id

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

if {[bboard_get_topic_info] == -1} {
    return
}

set return_url [bboard_raw_backlink $topic_id $topic $presentation_type 1]

if { $presentation_type == "usgeospatial" } {
    if { $refers_to == "NEW" } {
	if { [info exists tri_id] && ![empty_string_p $tri_id] } {
	    # we have a tri_id, have to look up epa region
	    set selection [ns_db 1row $db_sub "select st as usps_abbrev, sema_zip as zip_code, fips_county_code from rel_search_fac where tri_id = '$QQtri_id'"]
	    set_variables_after_query
	    set epa_region [database_to_tcl_string $db_sub "select epa_region from bboard_epa_regions where usps_abbrev = '$usps_abbrev'"]
	}
	# we'll send them back to the region level
	set full_anchor "<a href=\"usgeospatial-2.tcl?[export_url_vars topic topic_id epa_region]\">the $topic (Region $epa_region) forum</a>"
    } else {
	# a reply, try to send them back to their thread
	set full_anchor [bboard_usgeospatial_about_link $db $refers_to]
    }
} else {
    set full_anchor "<a href=\"[bboard_raw_backlink $topic_id $topic $presentation_type 0]\">$topic forum</a>"
}

## I moved the helper functions into defs.tcl

# check the user input first

set exception_text ""
set exception_count 0

if { ![info exists one_line] || [empty_string_p $one_line] } {
    append exception_text "<li>You need to type a subject line\n"
    incr exception_count
}

if { ![info exists message] || [empty_string_p $message] } {
    append exception_text "<li>You need to type a message; there is no \"Man/woman of Few Words Award\" here. \n"
    incr exception_count
}

set selection [ns_db select $db "select the_regexp, scope, message_to_user
from bboard_bozo_patterns
where topic_id = $topic_id"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $scope == "one_line" || $scope == "both" } {
	# let's check the subject line for this regexp
	if [regexp -nocase $the_regexp $one_line] {
	    incr exception_count
	    append exception_text "<li>$message_to_user\n"
	    # you can only be a bozo once
	    break 
	}
    }
    if { $scope == "message" || $scope == "both" } {
	if [regexp -nocase $the_regexp $message] {
	    incr exception_count
	    append exception_text "<li>$message_to_user\n"
	    # you can only be a bozo once
	    break 
	}
    }
}

if { [string length $QQmessage] < 4000 } {
    # For now, we only check for duplicates if the message is shorter
    # than 4000 bytes.

    if [catch { set n_previous [database_to_tcl_string $db "
	select count(*) from bboard 
	where topic_id = $topic_id
	and one_line = '$QQone_line'
	and dbms_lob.instr(message,'$QQmessage') > 0"]} errmsg] {
	ns_log Notice "failed trying to look up previous posting: $errmsg"
    } else {
	# lookup succeeded

	if { $n_previous > 0 } {
	    incr exception_count
	    append exception_text "<li>There are already $n_previous messages in the database with the same subject line and body.  Perhaps you already posted this?  Here are the messages: <ul>"
	    set selection [ns_db select $db "
select u.first_names, u.last_name, u.email, bb.posting_time 
from bboard bb, users u
where bb.user_id= u.user_id
and bb.topic_id = $topic_id
and bb.one_line = '$QQone_line'
and dbms_lob.instr(message,'$QQmessage') > 0"]

	    while {[ns_db getrow $db $selection]} {
		set_variables_after_query
		append exception_text "<li>$posting_time by $first_names $last_name ($email)\n"
	    }
	    append exception_text "</ul>
If you are sure that you also want to post this message, then back up and change at least 
one character in the subject or message area, then resubmit."

	}
    }
}

if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# if we get here, the user input checked OK

# before we overwrite all of these user inputs, let's cat them
# together so that we can do instant keyword-specific alerts 

#check for the user cookie
set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl"
    return
}

# for people who are looking for a user's name or email,
# we need to get this from the users table
set selection [ns_db 1row $db "select first_names, last_name, email
from users
where user_id=$user_id"]
set_variables_after_query

set name "$first_names $last_name"

set indexed_stuff "$name $email $one_line $message"

ReturnHeaders

ns_write "[bboard_header  "Inserting Message"]

<h2>Inserting Message</h2>

into the $full_anchor

<hr>

We're going to try the insert now...

<p>

"

with_transaction $db {
    # this will grab the exclusive lock on the msg_id_generator table
    # that will keep another copy of this same script from doing anything
    # more than waiting here.
    
    set last_id [ns_set value [ns_db 1row $db "select last_msg_id from msg_id_generator for update of last_msg_id"] 0]
    
    set new_id [increment_six_char_digits $last_id]
    
    ns_db dml $db "update msg_id_generator set last_msg_id = '$new_id'"
    
    if { $refers_to == "NEW" } {
	# this is a new message
	
	set sort_key $new_id
	set final_refers_to "NULL"
    } else {
	# we are referring to some older message
	
	set final_refers_to "'$refers_to'"
	set sort_key_of_referred_to_msg [database_to_tcl_string $db "select unique sort_key from bboard where msg_id = '$refers_to'"]
	set new_sort_key_form [new_sort_key_form $sort_key_of_referred_to_msg]
	set highest_current_sort_key_at_this_level [database_to_tcl_string $db "select max(sort_key) from bboard where sort_key like '$new_sort_key_form'"]
	set sort_key [new_sort_key $sort_key_of_referred_to_msg $highest_current_sort_key_at_this_level]
    }
    
    
    # sometimes an optional $category variable is included
    if { [info exists category] && $category != "" } {
	set category_target ",category"
	set category_value ",'$QQcategory'"
    } else {
	set category_target ""
	set category_value ""
    }
    
    # sometimes an optional custom_sort_key and custom_sort_key_pretty
    if { ([info exists custom_sort_key] && $custom_sort_key != "") || ($custom_sort_key_p == "t" && $custom_sort_solicit_p == "t" && $custom_sort_key_type == "date") } {
	# there was a form var called "custom_sort_key" or we're looking 
	# for a magically encoded date
	set custom_target ",custom_sort_key"
	if { $custom_sort_key_type == "date" } {
	    # have to decode from widget
	    ns_dbformvalue [ns_conn form] custom_sort_key date custom_sort_key
	}
	set custom_value ",'[DoubleApos $custom_sort_key]'"
	if { [info exists custom_sort_key_pretty] && $custom_sort_key_pretty != "" } {
	    append custom_target ",custom_sort_key_pretty"
	    append custom_value ",'$QQcustom_sort_key_pretty'"
	}
    } else {
	set custom_target ""
	set custom_value ""
    }

    set usgeospatial_target ""
    set usgeospatial_value ""
    if { $presentation_type == "usgeospatial" } {
	if { ![info exists usgeospatial_p] || $usgeospatial_p != "t" } {
	    # we only want to accept postings from a specially
	    # constructed form
	    ns_write "<h3>Sorry</h3>

We're sorry but you've somehow managed to post to a geospatialized
forum without using the requisite form.  This is almost certainly
our programming error.  Please send us email to let us know how you
got here.

 [bboard_footer]"
	    
	    # stop execution of this thread
	    return
	}
	if { $refers_to == "NEW" } {
	    if { [info exists tri_id] && ![empty_string_p $tri_id] } {
		# we have a tri_id, let's fill out everything else from 
		# that (i.e., look up region, state, usps_abbrev, zip)
		set selection [ns_db 1row $db_sub "select st as usps_abbrev, sema_zip as zip_code, fips_county_code from rel_search_fac where tri_id = '$QQtri_id'"]
		set_variables_after_query
		set epa_region [database_to_tcl_string $db_sub "select epa_region from bboard_epa_regions where usps_abbrev = '$usps_abbrev'"]
		set usgeospatial_target ", epa_region, usps_abbrev, fips_county_code, zip_code, tri_id"
		set usgeospatial_value ", [ns_dbquotevalue $epa_region integer], [ns_dbquotevalue $usps_abbrev text], [ns_dbquotevalue $fips_county_code text], [ns_dbquotevalue $zip_code text], [ns_dbquotevalue $tri_id text]"
	    } else {
		set usgeospatial_target ", epa_region, usps_abbrev"
		set usgeospatial_value ", $epa_region, '$QQusps_abbrev'"
		if [info exists fips_county_code] {
		    append usgeospatial_target ", fips_county_code"
		    append usgeospatial_value ", '$QQfips_county_code'"
		}
		if [info exists zip_code] {
		    append usgeospatial_target ", zip_code"
		    append usgeospatial_value ", '$QQzip_code'"
		}
	    }
	} else {
	    # this is a reply
	    # pull all the geospatial columns from the preceding row
	    set selection [ns_db 1row $db_sub "select epa_region, usps_abbrev, fips_county_code, zip_code, tri_id from bboard where msg_id = '$QQrefers_to'"]
	    set_variables_after_query
	    set usgeospatial_target ", epa_region, usps_abbrev, fips_county_code, zip_code, tri_id"
	    set usgeospatial_value ", [ns_dbquotevalue $epa_region integer], [ns_dbquotevalue $usps_abbrev text], [ns_dbquotevalue $fips_county_code text], [ns_dbquotevalue $zip_code text], [ns_dbquotevalue $tri_id text]"
	}
    }

    set urgent_p_target ""
    set urgent_p_value ""
    if { [info exists urgent_p] && ![empty_string_p $urgent_p] } {
	set urgent_p_target ", urgent_p"
	set urgent_p_value ", '$QQurgent_p'"
    }

    # to provide some SPAM-proofing, we record the IP address
    set originating_ip [ns_conn peeraddr]

    # Work around inability of Oracle to handle string literals > 4k

    if { [string length $QQmessage] < 4000 } {
	ns_db dml $db "insert into bboard (user_id,msg_id,refers_to,topic_id,originating_ip,one_line,message,html_p,sort_key,posting_time${category_target}${custom_target}${usgeospatial_target}${urgent_p_target})
		values ($user_id,'$new_id',$final_refers_to,$topic_id,'$originating_ip','$QQone_line','$QQmessage', '$html_p','$sort_key',sysdate${category_value}${custom_value}${usgeospatial_value}${urgent_p_value})"
    } else {
	ns_ora clob_dml $db "insert into bboard (msg_id,refers_to,topic_id,originating_ip,user_id,one_line,message,html_p,sort_key,posting_time${category_target}${custom_target}${usgeospatial_target}${urgent_p_target})
 values ('$new_id',$final_refers_to,$topic_id,'$originating_ip',$user_id,'$QQone_line',empty_clob(),'$html_p','$sort_key',sysdate${category_value}${custom_value}${usgeospatial_value}${urgent_p_value})
returning message into :1" $message
    }

    # Insert thread notifications
    if { $notify == "t" } {
        # (bran Feb 13 2000)
        set notify_thread_id [string range $sort_key 0 5]
	# Check for existing notifications for same thread.
	set n_alerts [database_to_tcl_string $db "select count(*)
from bboard_thread_email_alerts
where thread_id = '$notify_thread_id'
and user_id = $user_id"]
	if { $n_alerts == 0 } {
	    ns_db dml $db "insert into bboard_thread_email_alerts (thread_id, user_id) values ('$notify_thread_id', $user_id)"
	}
    }
    
    # Handle image uploading
    if {[bboard_file_uploading_enabled_p] && [info exists upload_file] && ![empty_string_p $upload_file]} {
	set tmp_filename [ns_queryget upload_file.tmpfile]
	set new_upload_id [database_to_tcl_string $db "select bboard_upload_id_sequence.nextval from dual"]
	set local_filename [bboard_generate_upload_filename $new_id $new_upload_id $upload_file]
	set full_local_path "[bboard_file_path]/$local_filename"
	ns_log Notice "Received $upload_file for upload; going to try to put it in $full_local_path"
	set n_bytes [file size $tmp_filename]
	if { $n_bytes > 0 } {
	    # we have a real image
	    ns_cp $tmp_filename $full_local_path
	    if { [info exists caption] && ![empty_string_p $caption] } {
		# we have a photo 
		set extra_uf_columns ", caption"
		set extra_uf_values ", [ns_dbquotevalue $caption text]"
		set file_type "photo"
	    } else {
		set extra_uf_columns ""
		set extra_uf_values ""
		set file_type "not a photo"
	    }
	    # make sure to lowercase it so we don't have to 
	    # deal with JPG and JPEG
	    set file_extension [string tolower [file extension $upload_file]]
	    # remove the first . from the file extension
	    regsub "\." $file_extension "" file_extension
	    set what_aolserver_told_us ""
	    if { $file_extension == "jpeg" || $file_extension == "jpg" } {
		catch { set what_aolserver_told_us [ns_jpegsize $full_local_path] }
	    } elseif { $file_extension == "gif" } {
		catch { set what_aolserver_told_us [ns_gifsize $full_local_path] }
	    }
	    # the AOLserver jpegsize command has some bugs where the height comes 
	    # through as 1 or 2 
	    if { ![empty_string_p $what_aolserver_told_us] && [lindex $what_aolserver_told_us 0] > 10 && [lindex $what_aolserver_told_us 1] > 10 } {
		set original_width [lindex $what_aolserver_told_us 0]
		set original_height [lindex $what_aolserver_told_us 1]
	    } else {
		set original_width ""
		set original_height ""
	    }
	    # strip off the C:\directories... crud and just get the file name
            # (branimir 2000/04/09)
            # For some reason the earlier regexp {([^//\]+)$} doesn't
            # work any more in Tcl 8.2.  The new {([^//\\]+)$} works
            # everywhere.
	    if ![regexp {([^//\\]+)$} $upload_file match client_filename] {
		# couldn't find a match
		set client_filename $upload_file
	    }

		 ns_db dml $db "insert into bboard_uploaded_files (bboard_upload_id, msg_id, file_type, file_extension, n_bytes, client_filename, filename_stub$extra_uf_columns,original_width,original_height)
 values ($new_upload_id, '$new_id', '$file_type', '$file_extension', $n_bytes, '[DoubleApos $client_filename]', '/$local_filename'$extra_uf_values,[ns_dbquotevalue $original_width number],[ns_dbquotevalue $original_height number])"
	     }
	}
    } {
	# something went a bit wrong during the insert
	ns_write "<h3>Ouch!!</h3>

Here was the bad news from the database:
<pre>

$errmsg $QQrefers_to

</pre>

Don't quit your browser.  You might be able to resubmit your posting
five or ten minutes from now.

 [bboard_footer]
"
	return
    }

    ns_write "<h3>Success!!</h3>

Your posting is now in the database.

One of the big points of <a href=\"http://photo.net/wtr/thebook/\">this software</a> is to support collaboration
using the best mix of Web and email.  Now that we've done the Web part,
we will notify the people who have requested an
<a href=\"add-alert.tcl?[export_url_vars topic topic_id]\">email alert</a>.
You may move to a different url if you don't want to wait for this process
to complete.
<P>
<ul>
<li> Generating alerts...
<p>
"

    # email_queue is a list; each elementof the list is an ns_set 
    # containing information about an email to be sent
      
    # The keys in each ns_set:
    # to: to email
    # from: from email
    # subject:  subject heading
    # body:  body
    # user_message: message to output to the Web user about this email
    # extraheaders: ns_set containing header name/content pairs for ns_sendmail
   
    set email_queue [list]
    # the WRAP=HARD in our form's TEXTAREA should have wrapped but 
    # let's make sure (in case user's browser wasn't being nice to us)
    # also, let's try to 
    if { $html_p == "t" } { 
	set message_wrapped [wrap_string [util_striphtml $message]]
    } else {
	set message_wrapped [wrap_string $message]
    }

    if { $notify_of_new_postings_p == "t" } {
	# administrator has requested notification of every new posting
	set maintainer_body "$name ($email) added a message to the $topic bboard:

Subject:  $one_line

$message_wrapped

----------

If you want to delete the message, come to the administration page:

 [bboard_url_stub]admin-home.tcl?[export_url_vars topic topic_id]

"
     set email_queue_entry [bboard_build_email_queue_entry $maintainer_email $email $one_line $maintainer_body "<li>sent email to the forum maintainer:  $maintainer_email"]
        lappend email_queue $email_queue_entry
     } else {
	 ns_write "<li>the forum maintainer ($maintainer_email) must be busy because he/she has disabled email notification of new postings\n\n<p>\n\n"
     }

     if { $refers_to != "NEW" } {

        # try to send email to all the previous posters

	# set up top, conditionally
#	set return_url "[bboard_url_stub]main-frame.tcl?[export_url_vars topic topic_id]"

	set from "$email"
	if { ![regexp {Response} $one_line] } {
	    set subject_line "Response to your posting: $one_line"
	} else {
	    set subject_line $one_line
	}
    #(bran Feb 19 2000 adding link to bring people directly to the thread)
    set msg_id [string range $sort_key 0 5]
    set body "$name ($email) responded to a message you 
requested notification for in the $topic bboard:

Subject:  $one_line

$message_wrapped

-----------------

To post a response, come back to the bulletin board at

[bboard_url_stub]q-and-a-fetch-msg.tcl?[export_url_vars msg_id topic_id topic]

"

    set email_queue [notify_if_requested_build $db [string range $sort_key 0 5] $from $subject_line $body]
    
    }

    # now we have to deal with all of the people who've requested instant notification of new postings

    # comment this out to avoid an AOLserver/Hearst mailer bug
    #    set from "$name <$email>"
    set from $email
    if { [string length $topic] < 10 } {
	set subject_line "$topic forum:  $one_line"
    } else {
	set subject_line "$one_line"
    }
    set msg_id [string range $sort_key 0 5]
    set body "
$message_wrapped

---------

To post a response, come back to the forum at

[bboard_url_stub]q-and-a-fetch-msg.tcl?[export_url_vars msg_id topic_id topic]

 (which is also the place to go if you want to edit your alerts and
stop these robotically sent messages)

"

    # **** Null/empty string problem for "keywords" (Oracle 9?)
    set selection [ns_db select $db "select distinct bboard_email_alerts.user_id,bboard_email_alerts.rowid, email from bboard_email_alerts, users_alertable 
where topic_id=$topic_id
and frequency='instant'
and valid_p = 't'
and keywords is null
and bboard_email_alerts.user_id = users_alertable.user_id"]

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if { ![bboard_already_notified_p $email $email_queue] } {
	    # user hasn't been queued recieved the note yet
	    set customized_body "$body

If you are annoyed by this message then just enter the following URL
into a browser and you'll disable the alert that generated this mail:

 [bboard_hardwired_url_stub]alert-disable.tcl?rowid=[ns_urlencode $rowid]
"

            set extraheaders [ns_set create extraheaders]
            ns_set put $extraheaders Reply-To $from

            lappend email_queue [bboard_build_email_queue_entry $email [bboard_sender_email] $subject_line $customized_body "<li>sent a note to $email \n" $extraheaders]
       }
   } 
   
   set selection [ns_db select $db "select distinct bboard_email_alerts.user_id, keywords, bboard_email_alerts.rowid, email 
from bboard_email_alerts, users_alertable
where topic_id=$topic_id
and frequency='instant'
and valid_p = 't'
and keywords is not null
and users_alertable.user_id = bboard_email_alerts.user_id"]

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	set keyword_list [split $keywords " "]
	set found_p 0
	foreach word $keyword_list {
	    # turns out that "" is never found in a search, so we
	    # don't really have to special case $word == ""
	    if { $word != "" && [string first [string toupper $word] [string toupper $indexed_stuff]] != -1 } {
		# found it!
		set found_p 1
	    }
	}
	if { $found_p == 1 && ![bboard_already_notified_p $email $email_queue] } {
	    # word is found and user hasn't been
	    # queued to receive the email yet
	    set customized_body "$body

If you are annoyed by this message then just enter the following URL
into a browser and you'll disable the alert that generated this mail:

 [bboard_hardwired_url_stub]alert-disable.tcl?rowid=[ns_urlencode $rowid]
"

            set extraheaders [ns_set create extraheaders]
            ns_set put $extraheaders Reply-To $from

            lappend email_queue [bboard_build_email_queue_entry $email [bboard_sender_email] $subject_line $customized_body "<li>sent a note to $email \n" $extraheaders]
        }
    } 

    # we release the database handle in case the mailer is down; we 
    # don't want other threads to block waiting for a db handle tied
    # down by us 
    ns_db releasehandle $db

    # send out the email
    
    if { ![philg_development_p] } {
	foreach email $email_queue {
	    with_catch errmsg {
		ns_sendmail [ns_set get $email to] [ns_set get $email from] [ns_set get $email subject] [ns_set get $email body] [ns_set get $email extraheaders]
		# we succeeding sending this particular piece of mail
		ns_write [ns_set get $email user_message]
	    } {
		# email failed, let's see if it is because mail 
		# service is completely wedged on this box
		if { [string first "timed out" errmsg] != -1 } {
		    # looks like we couldn't even talk to mail server
		    # let's just give up and return so that this thread
		    # doesn't have around for 10 minutes 
		    ns_log Notice "timed out sending email; giving up on email alerts.  Here's what ns_sendmail returned:\n$errmsg"
		    ns_write "</ul>
		
Something is horribly wrong with the email handler on this computer so
we're giving up on sending any email notifications.  Your posting
will be enshrined in the database, of course.
		
 [bboard_footer]"
		    return
		} else {
		    ns_write  "Something is horribly wrong with 
the email handler on this computer so
we're giving up on sending any email notifications.  Your posting
will be enshrined in the database, of course.


<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
		    return
		}
	    }
	}
    }
    
    # we're done processing the email queue
    ns_write "</ul>
<p>

We're all done with the email notifications now.  If any of these
folks typed in a bogus/misspelled/obsolete email address, you may get a
bounced message in your inbox.

[bboard_footer]
"

