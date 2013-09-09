# tcl/spam-daemon.tcl

ad_library {
    
 Run a scheduled procedure to locate and send any spam messages which are 
 queued for a given date.

 This runs a routine to pick up files from the filesystem as specified by the daily_spam_files
 table.


 It also attempts to resume any incomplete spam-sending jobs upon server restart.
  
    @author hqm@arsdigita.com 
    @cvs-id spam-daemon.tcl,v 3.33.2.13 2000/07/31 18:26:26 kevin Exp
}

################################################

################
# Enable spam daemon to sweep the dropzone for spam files that are ready to send

ns_share -init {set spam_enable_daemon_p [ad_parameter "SpamDaemonEnabled" "spam" 1]} spam_enable_daemon_p

proc_doc spam_set_daemon_active {val} "Enable/disable daemon which scans dropzone" {
    ns_share spam_enable_daemon_p
    set spam_enable_daemon_p $val
}

proc_doc spam_daemon_active_p {} "return state of Enable/disable dropzone scan daemon flag" {
    ns_share spam_enable_daemon_p
    return $spam_enable_daemon_p
}


################
# enable outgoing spam mailer
ns_share -init {set spam_email_sending_enabled_p 1} spam_email_sending_enabled_p

proc_doc spam_set_email_sending {val} "Enable/disable email sending of spam" {
    ns_share spam_email_sending_enabled_p
    set spam_email_sending_enabled_p $val
}

proc_doc spam_email_sending_p {} "return state of Enable/disable spam email flag" {
    ns_share spam_email_sending_enabled_p
    return $spam_email_sending_enabled_p
}


################ 
# Switch to use bulk mailer instead of ns_sendmail
ns_share -init {set use_bulkmail_p 0} use_bulkmail_p

proc_doc spam_set_use_bulkmail_p {val} "Enable/disable use of bulk mailer for sending of spam" {
    ns_share use_bulkmail_p
    set use_bulkmail_p $val
}

proc_doc spam_use_bulkmail_p {} "return state of use_bulkmail_p spam email flag" {
    ns_share use_bulkmail_p
    return $use_bulkmail_p
}


# DEPRECATED: we are now using a subselect to isolate the raw SQL from the user-classes module
# so we don't even have to try to mess with the actual SQL.
proc_doc spam_rewrite_user_class_query {raw_query}  {Rewrites a SQL query which came from the user-class module to be a query suitable for the spam module. This kludge will hopefully not be needed soon.  } {
    return $raw_query
}

ad_proc -private spam_post_new_spam_message {
    -spam_id:required
    {-template_p "f"}
    {-from_address ""}
    {-title ""}
    {-body_plain ""}
    {-body_html ""}
    {-body_aol ""}
    {-target_users_description ""}
    {-target_users_query ""}
    {-send_date ""}
    {-creation_user ""}
    {-status "unsent"}
} { 
Insert a message to be sent by the spam daemon at a scheduled time send_date.
<p>
send_date should be a string of the form "YYYY-MM-DD HH24:MI:SS" or else an empty string.
If send_date is an empty string, then sysdate is used (send as soon as possible). 
<p>
Returns spam_id, the id of the newly created message in the spam_history table.
} {

    # Validate that all mandatory arguments have been supplied.
    #
    set missing_args [list]


    if { [string match $status "hold"] == -1 && [empty_string_p $body_plain] } {
	lappend missing_args "body_plain"
    }

    if { [empty_string_p $creation_user] } {
	lappend missing_args "creation_user"
    }

    set n_missing_args [llength $missing_args]

    if { $n_missing_args > 0 } {
	error "missing $n_missing_args arg(s): [join $missing_args ", "]"
    }

    set sql_send_date [db_nullify_empty_string  $send_date]
    
    #set spam_id [db_nextval "spam_id_sequence"]

    db_dml insert_new_spam "insert into spam_history
            (spam_id, template_p, from_address, title,
             body_plain, body_html, body_aol,
             user_class_description, user_class_query,
             send_date, creation_date, creation_user,
             status, creation_ip_address,pathname)
           values
            (:spam_id, 
             :template_p,
             :from_address,
             :title,
             empty_clob(),
             empty_clob(),
             empty_clob(),
	     :target_users_description,
	     :target_users_query,
	     nvl(to_date(:sql_send_date, 'YYYY-MM-DD HH24:MI:SS'), sysdate), 
	     sysdate,
	     :creation_user,
	     :status,
	     '0.0.0.0', null)
           returning body_plain,
                     body_html,
                     body_aol into :1, :2, :3" -clobs [list $body_plain $body_html $body_aol]
    
    return $spam_id
}
  

# Creates a multipart/alternative MIME message with a plain text part and HTML part
# The two parts should be passed in encoded as  quoted-printable text.
proc spam_create_multipart_html_message_body {qp_body_plain qp_body_html} {
    set body "--[spam_mime_boundary]\n"
    append body "Content-Type: text/plain\n"
    append body "Content-Disposition: inline\n"
    append body "Content-Transfer-Encoding: quoted-printable\n"
    append body "\n"
    append body "$qp_body_plain\n"
    append body "\n"
    append body "--[spam_mime_boundary]\n"
    append body "Content-Type: text/html\n"
    append body "Content-Transfer-Encoding: quoted-printable\n"
    append body "Content-Disposition: inline\n"
    append body "\n"
    append body "$qp_body_html\n"
    append body "--[spam_mime_boundary]--\n"

    return $body

}

#
# This procedure is called periodically by a scheduled proc to send any spam 
# messages which are in the spam_history table that are at or
# past their target send dates

ns_share -init {set spam_daemon_sending_p 0} spam_daemon_sending_p

proc send_scheduled_spam_messages {} {
    ns_log Notice "running scheduled spam sending daemon"
    ns_share spam_daemon_sending_p
    ns_share spam_email_sending_enabled_p
    ns_share use_bulkmail_p

    if {$spam_email_sending_enabled_p == 0} {
	ns_log Notice "spam daemon is disabled via the spam_email_sending_enabled_p flag"
	return
    }

    if {$spam_daemon_sending_p != 0} {
	ns_log Notice "send_scheduled_spam_messages: in another thread, a spam daemon process is busy running, returning"
	return
    }


    set spam_daemon_sending_p 1

    # We loop pulling spams out of the spam_history table that
    # are ready to send. Warning: there is a race condition here -
    # if another thread tries to scan the queue simultaneously, then
    # there is a danger of two threads trying to send the same spam.
    # In production, make sure that the only one who calls this function
    # is a single scheduled proc, to avoid this condition. 
    #
    # It is also possible to rewrite this as an "update" query to do an atomic
    # grab of the top item on the queue and move it to "sending" state
    # simultaneously. That would fix the race condition. [hqm]

    set more_spam_p 1
    if [catch {

	# Check for files deposited by users as specified in the daily_spam_files table
	if {[spam_daemon_active_p]} {
	    check_spam_drop_zone
	}

	while { $more_spam_p } {
	    ns_log Notice "send_scheduled_spam_messages: checking spam_history queue"

	    # Pick the spam which is furthest past deadline of all
	    # spams which have current or past-due deadlines,and
	    # which have not already been processed.

	    set spam_row_set [ns_set create]
	    set more_spam_p [db_0or1row overdue_spam "
		SELECT spam_id
		   ,creation_user
		   ,from_address
		   ,body_plain
		   ,body_html
		   ,body_aol
		   ,title
		   ,user_class_query
		   ,user_class_description
		   ,send_date
		   ,status
		   ,last_user_id_sent
		   ,template_p
		  FROM spam_history
		 WHERE spam_id = (select min(spam_id) 
	                           from spam_history 
                                  where send_date <= sysdate 
                                        and (status = 'unsent' OR status = 'interrupted'))
              " -column_set spam_row_set]

	    # If no more spams are pending, we can quit for now
		
	    if { $more_spam_p }  {
		
		set spam_id [ns_set get $spam_row_set "spam_id"]
		set user_class_description [ns_set get $spam_row_set "user_class_description"]

		db_dml update_begin_send_time "
		UPDATE spam_history
                   SET status = 'sending'
		       ,begin_send_time = sysdate
		 WHERE spam_id = :spam_id"
	    
		ns_log Notice "spam_daemon: sending spam_id $spam_id '$user_class_description'"

		send_spam_message $spam_row_set
	    }
	}
    } errmsg] {
	ns_log Error "error in send_scheduled_spam_messages: $errmsg"
    }

    set spam_daemon_sending_p 0
}


# spam_row_set contains a spam row from spam_history.
# Extract the msg bodies and target recipients list query from the spam msg, and
# send email to the recipients.
proc send_spam_message {spam_row_set} {
    ns_share spam_daemon_sending_p
    ns_share spam_email_sending_enabled_p
    ns_share use_bulkmail_p

    set_variables_after_query_not_selection $spam_row_set

    # sets these vars
    #    spam_id
    #    creation_user
    #    from_address
    #    body_plain
    #    body_html
    #    body_aol
    #    title
    #    user_class_query
    #    user_class_description
    #    send_date
    #    status
    #    last_user_id_sent
    #    template_p
    
    ns_log Notice "send_spam_message: got spam_id=$spam_id, from_address=$from_address, title=$title"
    
   
    if {[empty_string_p $user_class_description]} {
	set user_class_description "ACS mailing list unnamed"
    }

    # These hold any extra mail headers we want to send with each message.
    # Headers for HTML mail
    set msg_html_headers [ns_set create]
    ns_set update $msg_html_headers "Mime-Version" "1.0"
    ns_set update $msg_html_headers "Content-Type" "multipart/alternative; boundary=\"[spam_mime_boundary]\""
    ns_set update $msg_html_headers "X-User-Class-List" $user_class_description


    
    
    # Headers for AOL mail
    set msg_aol_headers [ns_set create]
    ns_set update $msg_aol_headers "Content-type" "text/html; charset=\"iso-8859-1\""
    
    # Headers for plain text mail
    set msg_plain_headers [ns_set create]
    
    ################
    # For each spam, get the list of interested users, and send mail.
    
    # standard query but make sure that we don't send to dont_spam_me_p or
    # deleted_p users
    
    if {![info exists last_user_id_sent] || [empty_string_p $last_user_id_sent]} {
	set last_user_id_sent 0
    }
    
    # Note how we isolate the user_class_query in a subquery. This is
    # potentially inefficient, but safe, and maybe the Oracle optimizer
    # can do something smart with it.
    set query "SELECT c.user_id
                      ,uspam.email
                      ,up.email_type
                      ,uspam.first_names
                      ,uspam.last_name
                 FROM ($user_class_query) c, users_spammable uspam, users_preferences up
                WHERE up.user_id = uspam.user_id
                  AND uspam.user_id = c.user_id
                  AND uspam.user_id > $last_user_id_sent
                ORDER BY c.user_id"

    ns_log Notice "SEND_SPAM_MESSAGE:  1) query = $query"
    

    db_with_handle db {
	if {$use_bulkmail_p == 1} {
	    set bulkmail_id [bulkmail_begin $creation_user "spam_id $spam_id"]
	} else {
	    set bulkmail_id ""
	}
    }
    
    # query sets user_id for each interested user
    
    # more accurate flow rate if we set this as the start time, because above query takes
    # a couple minutes sometimes
    db_dml update_send_time "update spam_history set begin_send_time = sysdate where spam_id = :spam_id"
    


    set send_count 0
    
    # Send the spam to the recipients
    set send_count [spam_send_msg_to_recipients $query $spam_id $from_address $body_plain $body_html $body_aol $msg_plain_headers $msg_html_headers $msg_aol_headers $template_p $title $bulkmail_id]
    
    set logging_frequency [spam_checkpoint_logging_frequency]

    # close out the bulkmail run if needed, add up the last group of users sent
    if {$use_bulkmail_p == 1} {
	bulkmail_end $bulkmail_id
    }

    db_dml update_last_send_count "update spam_history 
                                      set n_sent = n_sent + [expr $send_count % $logging_frequency]
                                   where spam_id = :spam_id"
    
    db_dml update_finish_time "update spam_history
                                  set status = 'sent', finish_send_time = sysdate 
                                where spam_id = :spam_id"

    ns_log Notice "moving spam_id $spam_id to \"sent\" state"
}

# Checkpoint the last user_id message was sent to, every n msgs
proc spam_checkpoint_logging_frequency {} {
    return 20
}


# send spam messages to a list of users.
proc spam_send_msg_to_recipients {
    recipients_query
    spam_id
    from_address
    body_plain
    body_html
    body_aol
    msg_plain_headers
    msg_html_headers
    msg_aol_headers
    template_p
    title
    bulkmail_id
} {

    ns_share spam_daemon_sending_p
    ns_share spam_email_sending_enabled_p
    ns_share use_bulkmail_p

    # how often we update the n_sent field of the spam record
    set logging_frequency [spam_checkpoint_logging_frequency]
    
    #Get site-wide removal blurb
    set txt_removal_blurb  [ad_removal_blurb "" "txt"]
    set html_removal_blurb [ad_removal_blurb "" "htm"]
    set aol_removal_blurb  [ad_removal_blurb "" "aol"]

    # Make a quoted printable encoding of the content plus removal blurb
    regsub -all "\r" $body_html "" full_html_msg
    append full_html_msg $html_removal_blurb
    set qp_body_html [spam_encode_quoted_printable $full_html_msg]
    
    regsub -all "\r" $body_plain "" body_plain_full
    append body_plain_full "\n\n$txt_removal_blurb"
    set qp_body_plain [spam_encode_quoted_printable $body_plain_full]
    
    # The SQL which generates the list of target users may be badly formed
    # (perhaps it was created by hand). So we need to put a catch here and
    # skip over this spam if it is causing an error. 
    # Mark the spam as 'error' to keep it from being retried forever.

    set send_count 0

    if [catch {
	db_foreach spam_recipients_list $recipients_query {
	    
	    if {![info exists email_type]} {
		set email_type "text/plain"
	    }
	    
	    if {$spam_email_sending_enabled_p == 0} {
		ns_log Notice "** spam disabled:  spam to $user_id, $email, \"$title\""
		break
	    }
	    
	    # remove spaces from email address (since user registration doesn't currently do this)
	    # since these are almost certainly bogus
	    regsub -all " " $email "" email
	    
	    #
	    # If the HTML or AOL spam message text is null, revert to sending plain text to everyone
	    if { [empty_string_p $email_type] } {
		set email_type "text/plain"
	    } elseif { [string compare $email_type "text/html"] == 0 && [empty_string_p $body_html] } {
		set email_type "text/plain"
	    } elseif { [string compare $email_type "text/aol-html"] == 0 && [empty_string_p $body_aol] } {
		set email_type "text/plain"
	    }
	    
	    switch $email_type {
		"text/html" { 
		    set extra_headers [ns_set copy $msg_html_headers]
		    set message_body_template [spam_create_multipart_html_message_body $qp_body_plain $qp_body_html]
		}
		"text/aol-html" { 
		    set extra_headers [ns_set copy $msg_aol_headers]
		    set message_body_template "$body_aol\n$aol_removal_blurb"
		}
		default {
		    set extra_headers [ns_set copy $msg_plain_headers]
		    set message_body_template "$body_plain_full"
		}
	    }
	    
	    if {[string match $template_p "t"]} {
		if [catch {
		    global ad_sec_user_id
		    set message_body [subst $message_body_template]
		    set title [subst $title]
		} errmsg] {
		    ns_log Error "Tcl evaluator error in subst call for spam_id $spam_id: $errmsg\nAborting the sending of this spam."
		    break
		}
	    } else {
		set message_body $message_body_template
	    }
	    
	    regsub -all -nocase "%%EMAIL%%" $message_body $email message_body_template
	    
	    if [info exists first_names] {
		regsub -all -nocase "%%FIRST_NAMES%%" $message_body_template $first_names message_body_template
	    }
	    
	    if [info exists last_names] {
		regsub -all -nocase "%%LAST_NAMES%%" $message_body_template $last_names message_body_template
	    }
	    
	    set message_body $message_body_template
	    
	    ns_log Notice "Sending spam to $email, \"$title\""
	    if {$spam_email_sending_enabled_p == 0} {
		ns_log Notice "** spam disabled:  spam to $user_id, $email, \"$title\""
		set spam_daemon_sending_p 0
		break
	    } else {
		if {$use_bulkmail_p == 1} {
		    # The sender address is overwritten automatically by the bulkmailer
		    bulkmail_send $bulkmail_id $user_id $email $from_address $title $message_body {} $extra_headers
		} else {
		    ns_sendmail $email $from_address $title $message_body $extra_headers
		}
	    }
	    
	    # we log this every N sends, to keep the overhead down
	    incr send_count
	    if {[expr $send_count % $logging_frequency] == 0} {
		db_dml update_send_count "
		UPDATE spam_history 
		   SET last_user_id_sent = :user_id,
                       n_sent = n_sent + :logging_frequency 
                 WHERE spam_id = :spam_id"
	    }
	}
    } errmsg] {
	ns_log Error "Tcl evaluator/db-error when executing user_class_query in send_scheduled_spam_messages: sql=$recipients_query\errmsg=$errmsg\nAborting the sending of spam_id $spam_id."
	db_dml spam_error "update spam_history set status = 'error' where spam_id = :spam_id"
    }
    return $send_count
}
    
    

################################################################
# Load up table of default email types from config .ini file

proc config_default_email_types {} {
    db_dml install_default_email_types_delete "delete from default_email_types"
    set email_types [ad_parameter EmailTypes "spam"]
    ns_log Notice "email_types = $email_types"
    foreach entry $email_types {
	set pattern [lindex $entry 0]
	set mime_type [lindex $entry 1]
	db_dml install_default_email_types_init "insert into default_email_types (pattern, mail_type) values (:pattern, :mime_type)"
    }
}

#ad_schedule_proc -once t 5 config_default_email_types


# Any spam which is in the "sending" state when the server is restarted was
# clearly interrupted in the middle of a send job. So we move it to the 'interrupted'
# state (which is effectively just another name for the 'unsent' state). The 
# next thread which calls send_scheduled_spam_messages will then grab the
# lock on it (so to speak), by moving it to the sending state, and start 
# resume emails at the last user_id which was sent to. 
#

proc flag_interrupted_spams {} {
    db_foreach list_interrupted_spams "select spam_id, creation_date, title
                                           from spam_history where status = 'sending'" {

       ns_log Notice "moving spam $spam_id, $creation_date '$title' to interrupted state"
   }
   db_dml flag_interrupted_spams "update spam_history set status = 'interrupted' where status = 'sending'"
}



set spam_server_restarted_delay 10
if {[spam_daemon_active_p]} {
    ad_schedule_proc -once t $spam_server_restarted_delay flag_interrupted_spams
}

################################################################
# Scan for messages past deadline, once per hour, and send them if needed. 
#
# The flag_interrupted_spams routine above must be run exactly ONCE at server
# restart time, before send_scheduled_spam_messages is run. This allows the
# system to move any spams jobs that were interrupted into the "interrupted" state,
# where they can be resumed by a thread running the spam daemon.
#
# 

ns_share -init {set spam_daemon_installed 0} spam_daemon_installed

if {!($spam_daemon_installed) && [spam_daemon_active_p] } {
    set spam_daemon_installed 1
    ns_log Notice "Scheduling spam sender daemon"
    set interval [ad_parameter QueueSweepInterval "spam" [expr 1800 + $spam_server_restarted_delay]]
    ad_schedule_proc -thread t $interval send_scheduled_spam_messages
}

proc spam_file_location {filename} {
    set page_root [ns_info pageroot]
    regsub {/www$} $page_root {/spam} spam_root
    return "[ad_parameter "DailySpamDirectory" "spam" $spam_root]/$filename"
}

proc read_file_as_string {pathname} {
    if { ![file exists $pathname] || ![file readable $pathname] } {
	return ""
    }
    set fd [open $pathname]
    set buf [read $fd]
    close $fd
    return $buf
}


proc get_spam_from_filesystem {filename} {
    set fname [spam_file_location $filename]
    return [read_file_as_string $fname]
}
   
    
################################################################

# Look for a set of files with names specfied from the daily_spam_files table
# 
# For example, file_prefix=daily looks for the file "daily[-MM-DD-YYYY]" as the indicator 
# that the spam is ready to go. The date is optional. If there is no dated file,
# the plain file prefix name will be used at the content source file.
#
# It will also look for aux files "daily-html[-MM-DD-YYYY]" and "daily-aol[-MM-DD-YYYY]"
# and if they exist, their content will be sent to users with those email type preferences.
#
# If no AOL file is found, but there is an HTML file, the HTML file's content will be used for the AOL
# content.
#
# Bug: There is thus a race condition, if the
# content file is only partially written when the daemon probes for it.
# A solution would be to use another dummy file whose existence indicates the 
# other spam files are complete and ready. Make sure to at least write the
# HTML and AOL files first, to close the race condition window a little.
#
# Note: if you omit the date from a filename, the same file will be picked up and
# sent once per day. This usually is not what you want.
# 

# day_of_week, day_of_month, day_of_year, start at 1, not 0

proc check_spam_drop_zone {} {

    set date [db_string the_date "select to_char(sysdate,'MM-DD-YYYY') from dual"]
    set pretty_date [db_string pretty_date "select to_char(sysdate,'MM/DD/YYYY') from dual"]

    # outer loop - iterate over daily_spam_files table looking for descriptors of
    # files in the drop zone.

    db_foreach daily_spam_files "select file_prefix, from_address, subject, 
                    target_user_class_id, template_p, user_class_description,
                    period, day_of_week, day_of_month, day_of_year
               from daily_spam_files" {

	# depending if the period is daily, weekly, or monthly, compute the date
	# by which it needs to be sent.

	# If there exists a spam for this file-prefix within
	# the "last_sent_the window" condition defined below, then
	# is is too early to send a new periodic spam of that type.

	switch $period {
	    daily   { 
		# don't send two on the same day
		set last_sent_window " (trunc(sysdate) - trunc(send_date)) < 1 "
		set send_date_condition " 1 = 1 "
	    }
	    weekly  { 
		# +++ This needs to be internationalized somehow - it shouldn't
		# depend on english day names
		if {[empty_string_p $day_of_week]} {
		    set day_of_week 1
		}
		set last_sent_window "(sysdate - send_date) < 3 "
		set send_date_condition " trunc(sysdate-next_day(sysdate-7,'MONDAY')) = ($day_of_week - 1) "
	    }
	    monthly { 
		if {[empty_string_p $day_of_month]} {
		    set day_of_month 1
		}
		set last_sent_window " trunc(sysdate, 'MM') - trunc(send_date,'MM') = 0"
		set send_date_condition " trunc(sysdate - trunc(sysdate,'MM')) = ( $day_of_month - 1) "
	    }

	    yearly  { 
		if {[empty_string_p $day_of_year]} {
		    set day_of_year 1
		}
		set last_sent_window "(sysdate - (trunc(send_date,"YYYY"))) > ( $day_of_year - 1))"
		set send_date_condition "trunc(sysdate - trunc(sysdate,'YYYY')) = ( $day_of_year - 1)"
	    }
	    default { 
		set last_sent_window " (sysdate - send_date) < 1 "
		set send_date_condition "1 = 1"
	    }
	}

	# Check if a spam has already been queued for this file prefix and today's date or period
	set already_queued [db_string already_queued "select count(spam_id)
						       from spam_history 
						      where pathname = :file_prefix
							    and $last_sent_window " ]

	if { $already_queued > 0 } {
	    continue
	} else {

	    # check if the date today matches the send_date condition
	    set date_ok [db_string check_date "select count(1) 
                                                 from dual
                                                where $send_date_condition"]

	    if {$date_ok != 1} {
		continue
	    }
	    
	    # See if file prefix with date exists. If so, then look for other
	    # files with date appended.

	    set dropfile_path [spam_file_location $file_prefix]

	    ns_log Notice "checking for dropfile with and without date suffix: [set dropfile_path]-[set date]"
	    if { [file readable "[set dropfile_path]-[set date]"] } {
		set date_suffix "-$date"
	    } else {
		set date_suffix ""
	    }
	    
	    if { ![file readable "[set dropfile_path][set date_suffix]"] } {
		ns_log Notice "Daily spam for \"$file_prefix\" could not be sent - no dropfile found at [set dropfile_path]\[[set date_suffix]\]"
	    } else {

		# get the contents of files, and insert into queue
		# Check for file name which includes date
		set dropfile_path_plain "[set dropfile_path]$date_suffix"
		set dropfile_path_html  "[set dropfile_path]-html$date_suffix"
		set dropfile_path_aol   "[set dropfile_path]-aol$date_suffix"

		set file_plain [read_file_as_string $dropfile_path_plain]
		set file_html  [read_file_as_string $dropfile_path_html]
		set file_aol   [read_file_as_string $dropfile_path_aol]

		# Set other spam params
		if {[empty_string_p $from_address]} {
		    set from_address [spam_system_default_from_address]
		}

		regsub -all "%%DATE%%" $subject $pretty_date subject_x
		set system_user 1

		# generate SQL query from user_class_id
		set set_args [ns_set create]
		ns_set update $set_args "user_class_id" $target_user_class_id
		set query [spam_rewrite_user_class_query [ad_user_class_query $set_args]]

		db_dml queue_new_periodic_spam "
                     insert into spam_history
                        (spam_id,
		         template_p,
			 from_address,
			 title,
			 body_plain,
			 body_html,
			 body_aol,
			 user_class_description,
			 user_class_query,
			 send_date,
			 creation_date,
			 creation_user,
			 status,
			 creation_ip_address,
			 pathname)
	              values
			(spam_id_sequence.nextval,
			:template_p,
			:from_address,
			:subject_x,
			empty_clob(),
			empty_clob(),
			empty_clob(),
			:user_class_description,
			:query,
			sysdate,
			sysdate,
			:system_user,
			'unsent',
			'0.0.0.0',
			:file_prefix)
                     returning body_plain, body_html, body_aol into :1, :2, :3 
                   " -clobs [list $file_plain $file_html $file_aol]
		ns_log Notice "Daily spam queued for \"$file_prefix\" from $dropfile_path_plain"
	    }
	}
    }
}

proc spam_guess_email_type_preference {user_id} {
    return [db_string guess_email_pref "select guess_user_email_type(:user_id) from dual"]
}

proc_doc spam_sanitize_filename {filename} "Remove any pathname metachars from a filename, allow only a very clean set of characters" {
    regsub -all {[^A-aZ-z0-9._-]} $filename "_" file_clean
    regsub -all {[.]+} $file_clean "." file_clean_1
    return $file_clean_1
}


proc spam_set_to_string {s} {
    set result ""
    set setsize [ns_set size $s]
    set i 0
    while { $i < $setsize} {
	set result [linsert $result 0 [list [ns_set key $s $i] [ns_set value $s $i]]]
	incr i
    }

    return $result
}

proc spam_string_to_set {str} {
    set result [ns_set create]
    set i 0
    foreach item $str {
	set key [lindex $item 0]
	set data [lindex $item 1]
	ns_set put $result $key $data
	incr i
    }
    return $result
}
