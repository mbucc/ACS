ad_page_contract {
    Post the message into the bboards
    
    @param topic_id - topic id
    @param topic    - topics
    @param refers_to - is this message a child of another message
    @param one_line  - one line description of message
    @param notify    - notify the person if a response is posted
    @param message   - the message itself
    @param html_p    - is the message html format

    @author ?
    @creation-date ?
    @cvs-id insert-msg.tcl,v 3.12.2.13 2000/11/13 22:32:03 lars Exp
} {
    message:allhtml,notnull
    one_line:trim,notnull
    notify
    {html_p "f"}
    topic_id:integer,optional
    topic
    {category ""}
    refers_to
    {custom_sort_key ""}
    {custom_sort_key_pretty ""}
    {epa_region ""}
    {usps_abbrev ""}
    fips_county_code:optional
    zip_code:optional
    {upload_file ""}
    upload_file.tmpfile:tmpfile,optional
    {usgeospatial_p "f"} 
    {urgent_p ""} 
    {caption ""}
} -validate {
    html_p_ok { 
	if { ![string equal $html_p "t"] && ![string equal $html_p "f"] } {
	    ad_complain "html_p should be 't' for html-format, or 'f' for plaintext"
	}
    }
    html_security_check -requires { message:notnull } {
	if { [string equal $html_p "t"] } { 
	    set security_check [ad_html_security_check $message]
	    if { ![empty_string_p $security_check] } {
		ad_complain $security_check
	    }
	}
    }
}
    


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_handle_spammers

ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]


####################
#
# Email Queue proc
#
####################

# email_queue is a list; each elementof the list is an ns_set 
# containing information about an email to be sent
#
# The keys in each ns_set:
# to: to email
# from: from email
# subject:  subject heading
# body:  body
# user_message: message to output to the Web user about this email
# extraheaders: ns_set containing header name/content pairs for ns_sendmail

set email_queue [list]

# enqueues an email, but only if we haven't already an email on line for that person.

proc bboard_add_email_queue_entry {to from subject body user_message poster_email} {
    upvar email_queue email_queue

    # presumably the guy (m/f) doesn't want email about his own posting
    if { [string compare $to $poster_email] == 0 } {
	return
    }

    foreach email $email_queue {
	if { [string compare $to [ns_set get $email to]] == 0 } {
	    # email matched
	    return
	}
    }
    
    set email_ns_set [ns_set create email_queue_entry]
    ns_set put $email_ns_set to $to
    ns_set put $email_ns_set from $from
    ns_set put $email_ns_set subject $subject
    ns_set put $email_ns_set body $body
    ns_set put $email_ns_set user_message $user_message
    
    set extra_headers [ns_set create]
    ns_set put $extra_headers Reply-To $poster_email
    
    ns_set put $email_ns_set extraheaders $extra_headers
    
    lappend  email_queue $email_ns_set
}


####################
#
# Input validation
#
####################


# message, one_line, notify, html_p
# topic_id, topic are hidden vars
# refers_to is "NEW" or a msg_id (six characters)

# we MAY get an image or other file along with this msg, which means
# we'd get the file name in "upload_file" and can get out the temp file
# with ns_queryget

# we're going to need to subquery for instant keyword matching
# and/or looking around for state and county from tri_id
if {[bboard_get_topic_info] == -1} {
    return
}

if { $presentation_type == "usgeospatial" } {
    if { $refers_to == "NEW" } {
	# we'll send them back to the region level
	set full_anchor "<a href=\"usgeospatial-2?[export_url_vars topic topic_id epa_region]\">the $topic (Region $epa_region) forum</a>"
    } else {
	# a reply, try to send them back to their thread
	set full_anchor [bboard_usgeospatial_about_link $refers_to]
    }
} else {
    set full_anchor "<a href=\"[bboard_raw_backlink $topic_id $topic $presentation_type 0]\">$topic forum</a>"
}

# -----------------------------------------------------------------------------

# check the user input first
# Unfortunately not so well suited to using page_validation

set exception_text ""
set exception_count 0


db_foreach selection {
    select the_regexp, scope, message_to_user
    from bboard_bozo_patterns
    where topic_id = :topic_id
} {

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

if { [string length $message] < 4000 } {
    # For now, we only check for duplicates if the message is shorter
    # than 4000 bytes.

    if [catch { set n_previous [db_string dbl_click_check "
	select count(*) from bboard 
	where topic_id = :topic_id
	and one_line = :one_line
	and dbms_lob.instr(message,:message) > 0"]} errmsg] {
	ns_log Notice "failed trying to look up previous posting: $errmsg"
    } else {
	# lookup succeeded

	if { $n_previous > 0 } {
	    incr exception_count
	    append exception_text "<li>There are already $n_previous messages in the database with the same subject line and body.  Perhaps you already posted this?  Here are the messages: <ul>"

	    db_foreach bb_inst_first_name {
		select u.first_names
		, u.last_name
		, u.email
		, bb.posting_time 
		from bboard bb
		, users u
		where bb.user_id= u.user_id
		and bb.topic_id = :topic_id
		and bb.one_line = :one_line
		and dbms_lob.instr(message,:message) > 0
	    } {
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

####################
#
# Insert message into database
#
####################


# for people who are looking for a user's name or email,
# we need to get this from the users table
db_1row bb_insmg_user_info {
    select first_names || ' ' || last_name as name, email
    from users
    where user_id = :user_id
}


append page_content "[bboard_header  "Inserting Message"]
<h2>Inserting Message</h2>

into the $full_anchor

<hr>

We're going to try the insert now...

<p>

"

db_transaction {
    # this will grab the exclusive lock on the msg_id_generator table
    # that will keep another copy of this same script from doing anything
    # more than waiting here.

    # Ugh.  This is a huge amount of stuff to do in a transaction.

    set last_id [db_string bb_inmsg_next_id "
    select last_msg_id 
    from msg_id_generator 
    for update of last_msg_id"]
    
    set new_id [increment_six_char_digits $last_id]

    db_dml update_msg_id_generator {
	update msg_id_generator 
	set last_msg_id = :new_id
    }
    
    if {$refers_to == "NEW" } {
	# this is a new message
	
	set sort_key $new_id
	set final_refers_to [db_null]
    } else {
	# we are referring to some older message
	
	set final_refers_to $refers_to

	set sort_key_of_referred_to_msg [db_string refered_to {
	    select unique sort_key 
	    from bboard where msg_id = :refers_to
	}]

	set new_sort_key_form [new_sort_key_form $sort_key_of_referred_to_msg]

	set highest_current_sort_key_at_this_level [db_string max_sort_key "
	select max(sort_key) 
	from bboard 
	where sort_key like :new_sort_key_form"]

	set sort_key [new_sort_key $sort_key_of_referred_to_msg $highest_current_sort_key_at_this_level]
    }
    
    
    # sometimes an optional $category variable is included
    if { ![empty_string_p $category] } {
	set category_target ",category"
	set category_value ",:category"
    } else {
	set category_target ""
	set category_value ""
    }
    
    # sometimes an optional custom_sort_key and custom_sort_key_pretty
    # other vars come from bboard_topics
    if { ![empty_string_p $custom_sort_key] || \
	    ( $custom_sort_key_p == "t" && \
	      $custom_sort_solicit_p == "t" && \
	      $custom_sort_key_type == "date") } {

	# there was a form var called "custom_sort_key" or we're looking 
	# for a magically encoded date
	set custom_target ",custom_sort_key"

	if { $custom_sort_key_type == "date" } {
	    # have to decode from widget
	    ns_dbformvalue [ns_conn form] custom_sort_key date custom_sort_key
	}

	set custom_value ",:custom_sort_key"

	if { ![empty_string_p $custom_sort_key_pretty] } {
	    append custom_target ",custom_sort_key_pretty"
	    append custom_value ",:custom_sort_key_pretty"
	}

    } else {
	set custom_target ""
	set custom_value ""
    }

    set usgeospatial_target ""
    set usgeospatial_value ""
    if { $presentation_type == "usgeospatial" } {
	if { $usgeospatial_p != "t" } {
	    # we only want to accept postings from a specially
	    # constructed form
	    append page_content "<h3>Sorry</h3>

	    We're sorry but you've somehow managed to post to a geospatialized
	    forum without using the requisite form.  This is almost certainly
	    our programming error.  Please send us email to let us know how you
	    got here.

	    [bboard_footer]"
	    
	    # stop execution of this thread
	    # probably ought to be done using page_validation 
	    doc_return 200 text/html $page_content
	    return
	}

	if { $refers_to == "NEW" } {
	    set usgeospatial_target ", epa_region, usps_abbrev"
	    set usgeospatial_value ", :epa_region, :usps_abbrev"
	    if [info exists fips_county_code] {
		append usgeospatial_target ", fips_county_code"
		append usgeospatial_value ", :fips_county_code"
	    }
	    if [info exists zip_code] {
		append usgeospatial_target ", zip_code"
		append usgeospatial_value ", :zip_code"
	    }
	} else {
	    # this is a reply
	    # pull all the geospatial columns from the preceding row
	    db_1row db_sub {
		select epa_region, usps_abbrev, fips_county_code, zip_code
		from bboard 
		where msg_id = :refers_to
	    }

	    set usgeospatial_target ", epa_region, usps_abbrev, fips_county_code, zip_code"
	    set usgeospatial_value ", :epa_region, :usps_abbrev, :fips_county_code, :zip_code"
	}
    }

    # No longer need sub handle, release it here so we don't keep it through
    # image uploading below.

    set urgent_p_target ""
    set urgent_p_value ""
    if { ![empty_string_p $urgent_p] } {
	set urgent_p_target ", urgent_p"
	set urgent_p_value ", :urgent_p"
    }

    # to provide some SPAM-proofing, we record the IP address
    set originating_ip [ns_conn peeraddr]

    # Work around inability of Oracle to handle string literals > 4k

    if { [string length $message] < 4000 } {
	db_dml message_insert_no_clob "
	insert into bboard (user_id
	, msg_id 
	, refers_to
	, topic_id
	, originating_ip
	, one_line
	, message
	, html_p
	, sort_key
	, posting_time${category_target}${custom_target}${usgeospatial_target}${urgent_p_target})
	values(:user_id
	, :new_id 
	, :final_refers_to
	, :topic_id
	, :originating_ip
	, :one_line
	, :message 
	, :html_p
	, :sort_key 
	, sysdate${category_value}${custom_value}${usgeospatial_value}${urgent_p_value})"
    } else {
	db_dml msg_insert_with_clob "insert into bboard 
	( msg_id
	, refers_to
	, topic_id
	, originating_ip
	, user_id
	, one_line
	, message
	, html_p
	, sort_key
	, posting_time${category_target}${custom_target}${usgeospatial_target}${urgent_p_target})
	values (:new_id
	, :final_refers_to
	, :topic_id
	, :originating_ip
	, :user_id
	, :one_line
	, empty_clob()
	, :html_p
	, :sort_key
	, sysdate${category_value}${custom_value}${usgeospatial_value}${urgent_p_value})
	returning message into :1" -clobs [list $message]
    }

    # (bran Apr 4 2000)
    # Add new category if necessary
    set q_and_a_cats_user_extensible_p [db_string q_and_a_cats "
    select q_and_a_cats_user_extensible_p 
    from bboard_topics 
    where topic_id=:topic_id"]

    if {$q_and_a_cats_user_extensible_p == "t" && ![empty_string_p $category]} {
	# a semi-perverse way of checking that the category doesn't
	# already exist
	db_dml insert_category "
	insert into bboard_q_and_a_categories 
	(topic_id, category) 
	select :topic_id, :category 
	from dual 
	where :category not in (select category from bboard_q_and_a_categories)"
    }

    # Insert thread notifications
    if { $notify == "t" } {
        # (bran Feb 13 2000)
        set notify_thread_id [string range $sort_key 0 5]
	# Check for existing notifications for same thread.
	set n_alerts [db_string existing_alerts "
	select count(*)
	from bboard_thread_email_alerts
	where thread_id = :notify_thread_id
	and user_id = :user_id"]

	if { $n_alerts == 0 } {
	    db_dml unused "
	    insert into bboard_thread_email_alerts 
	    ( thread_id
	    , user_id) 
	    values 
	    ( :notify_thread_id 
	    , :user_id
	    )"
	}
    }
    
    # Handle image uploading
    if {[bboard_file_uploading_enabled_p] && ![empty_string_p $upload_file]} {
	set tmp_filename ${upload_file.tmpfile}

	set new_upload_id [db_string next_upload_id "
	select bboard_upload_id_sequence.nextval 
	from dual"]
	
	set local_filename [bboard_generate_upload_filename $new_id $new_upload_id $upload_file]
	set full_local_path "[bboard_file_path]/$local_filename"

	set n_bytes [file size $tmp_filename]
	if { $n_bytes > 0 } {
	    # we have a real image
	    ns_cp $tmp_filename $full_local_path

	    if { ![empty_string_p $caption] } {
		# we have a photo 
		set extra_uf_columns ", caption"
		set extra_uf_values ", :caption"
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

	    db_dml unused "
	    insert into bboard_uploaded_files 
	    ( bboard_upload_id
	    , msg_id
	    , file_type
	    , file_extension
	    , n_bytes
	    , client_filename
	    , filename_stub $extra_uf_columns
	    , original_width
	    , original_height)
	    values 
	    ( :new_upload_id
	    , :new_id 
	    , :file_type
	    , :file_extension 
	    , :n_bytes
	    , :client_filename
	    , :local_filename $extra_uf_values
	    , :original_width 
	    , :original_height)"
	}
    }
} on_error {
    # something went a bit wrong during the insert
    append page_content "<h3>Ouch!!</h3>

Here was the bad news from the database:
<pre>

$errmsg $refers_to

</pre>

Don't quit your browser.  You might be able to resubmit your posting
five or ten minutes from now.

 [bboard_footer]
"
    doc_return  200 text/html $page_content
    return
}

set msg_id [string range $sort_key 0 5]

append page_content "<h3>Success!!</h3>

Your posting is now in the database.
You can <a href=\"q-and-a-fetch-msg.tcl?[export_url_vars msg_id]\">go back to the thread</a> and see for yourself.

<p>

One of the big points of <a href=\"http://photo.net/wtr/thebook/\">this software</a> is to support collaboration
using the best mix of Web and email.  Now that we've done the Web part,
we will notify the people who have requested an
<a href=\"add-alert?[export_url_vars topic topic_id]\">email alert</a>.
You may move to a different url if you don't want to wait for this process
to complete.
<P>
<ul>
<li> Generating alerts...
<p>
"


# Takes too long to generate and send alerts.
ad_return_top_of_page $page_content
set page_content ""

####################
#
# Email notifications
#
####################

set msg_id [string range $sort_key 0 5]

set poster_name $name
set poster_email $email
set alerts_from_email [bboard_sender_email]

if { [string length $topic] < 10 } {
    set subject_line "$topic forum:  $one_line"
} else {
    set subject_line "$one_line"
}

set body_top "Posted by: $poster_name ($poster_email)
Topic    : $topic
Subject  : $one_line


[ad_convert_to_text -html_p $html_p -- $message]

--------------------

"

####################
#
# Notify maintainer
#
####################

if { $notify_of_new_postings_p == "t" } {
    # administrator has requested notification of every new posting

    set body "$body_top
If you want to delete the message, come to the administration page:

 [bboard_url_stub]admin-q-and-a-fetch-msg.tcl?[export_url_vars msg_id]

"
    bboard_add_email_queue_entry $maintainer_email $alerts_from_email $one_line $body \
	    "<li>sent email to the forum maintainer: $maintainer_email" $poster_email
} else {
    append page_content "<li>the forum maintainer ($maintainer_email) must be busy because he/she has
    disabled email notification of new postings<p>"
}



####################
#
# Thread alerts
#
####################

if { $refers_to != "NEW" } {

    db_foreach bb_inmsg_notify {
	select ua.email as notify_email, ea.rowid
	from bboard_thread_email_alerts ea, users_alertable ua
	where ea.thread_id = :msg_id
	and ea.user_id = ua.user_id
    } {
	set body  "$body_top
To post a response, come back to the bulletin board at

 [bboard_url_stub]q-and-a-fetch-msg.tcl?[export_url_vars msg_id]

If you are no longer interested in this thread, simply go to the
following URL and you will no longer get these notifications:

[bboard_url_stub]shut-up.tcl?row_id=[ns_urlencode $rowid]
"

        bboard_add_email_queue_entry $notify_email $alerts_from_email $subject_line $body \
		"<li>sent a note to $notify_email, who asked to be notified of responses." $poster_email
    }  
}



####################
#
# Instant alerts without keywords
#
####################


# **** Null/empty string problem for "keywords" (Oracle 9?)

db_foreach bb_inmsg_select {
    select distinct bboard_email_alerts.user_id, bboard_email_alerts.rowid, email as notify_email
    from bboard_email_alerts, users_alertable 
    where topic_id = :topic_id
    and frequency = 'instant'
    and valid_p = 't'
    and keywords is null
    and bboard_email_alerts.user_id = users_alertable.user_id
}  {
    
    set body "$body_top
To post a response, come back to the forum at

 [bboard_url_stub]q-and-a-fetch-msg.tcl?[export_url_vars msg_id]

 (which is also the place to go if you want to edit your alerts and
stop these robotically sent messages)
    
If you are annoyed by this message then just enter the following URL
into a browser and you'll disable the alert that generated this mail:

 [bboard_hardwired_url_stub]alert-disable.tcl?rowid=[ns_urlencode $rowid]
"

        bboard_add_email_queue_entry $notify_email $alerts_from_email $subject_line $body \
		"<li>sent a note to $notify_email" $poster_email
}



####################
# 
# Instant alerts with keywords
#
####################


db_foreach bb_ds_email {
    select distinct bboard_email_alerts.user_id, lower(keywords) as keywords, 
    bboard_email_alerts.rowid, email as notify_email
    from bboard_email_alerts, users_alertable
    where topic_id= :topic_id
    and frequency='instant'
    and valid_p = 't'
    and keywords is not null
    and users_alertable.user_id = bboard_email_alerts.user_id
    
} {

    set keyword_list [split $keywords " "]
    set indexed_stuff [string tolower "$poster_name $poster_email $one_line $message"]

    foreach word $keyword_list {
	
	if { [string first $word $indexed_stuff] != -1 } {

	    set body "$body_top
If you are annoyed by this message then just enter the following URL
into a browser and you'll disable the alert that generated this mail:

 [bboard_hardwired_url_stub]alert-disable.tcl?rowid=[ns_urlencode $rowid]
"

    	    bboard_add_email_queue_entry $notify_email $alerts_from_email $subject_line $body \
		    "<li>sent a note to $notify_email" $poster_email

            break
        }
    }
}

# we release the database handle in case the mailer is down; we 
# don't want other threads to block waiting for a db handle tied
# down by us 

db_release_unused_handles


####################
#
# Process the email queue
#
####################


if { ![philg_development_p] } {
    foreach email $email_queue {
	with_catch errmsg {
	    ns_sendmail [ns_set get $email to] [ns_set get $email from] [ns_set get $email subject] [ns_set get $email body] [ns_set get $email extraheaders]
	    # we succeeding sending this particular piece of mail
	    append page_content [ns_set get $email user_message]
	} {
	    # email failed, let's see if it is because mail 
	    # service is completely wedged on this box
	    if { [string first "timed out" errmsg] != -1 } {
		# looks like we couldn't even talk to mail server
		# let's just give up and return so that this thread
		# doesn't have around for 10 minutes 
		ns_log Notice "timed out sending email; giving up on email alerts.  Here's what ns_sendmail returned:\n$errmsg"
		append page_content "</ul>
		
Something is horribly wrong with the email handler on this computer so
we're giving up on sending any email notifications.  Your posting
will be enshrined in the database, of course.
		
 [bboard_footer]"
		return
	    } else {
		append page_content  "Something is horribly wrong with 
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
append page_content "</ul>
<p>

We're all done with the email notifications now.  If any of these
folks typed in a bogus/misspelled/obsolete email address, you may get a
bounced message in your inbox.

[bboard_footer]
"

#doc_return  200 text/html $page_content
ns_write $page_content