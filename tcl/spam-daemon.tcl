# spam-daemon.tcl
#
# hqm@arsdigita.com
#
# Run a scheduled procedure to locate and send any spam messages which are 
# queued for a given date.
#
# This runs a routine to pick up files from the filesystem as specified by the daily_spam_files
# table.
#
#
# It also attempts to resume any incomplete spam-sending jobs upon server restart.

################################################

util_report_library_entry

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



#
# This procedure is called daily by a scheduled proc to send any spam 
# messages which are in the spam_history table that are at or
# past their target send dates

proc send_scheduled_spam_messages {} {
    # +++ temporarily, we'll just use ns_sendmail until gregh's qmail API is set up
    # ns_sendmail is not guaranteed to do anything reasonable with envelopes, so
    # it is not obvious where bounced mail will come back to,
    # so until we get the new email transport running, watch out!

    ns_log Notice "running scheduled spam sending daemon"

    ns_share spam_email_sending_enabled_p
    ns_share use_bulkmail_p
    # how often we update the n_sent field of the spam record
    set logging_frequency 20

    if {$spam_email_sending_enabled_p == 0} {
	ns_log Notice "spam daemon is disabled via the spam_email_sending_enabled_p flag"
	return
    }

    set db_pools [ns_db gethandle main 2]
    set db [lindex $db_pools 0]
    set db2 [lindex $db_pools 1]

    # Check for files deposited by users as specified in the daily_spam_files table
    if {[spam_daemon_active_p]} {
	check_spam_drop_zone $db $db2
    }

    # We loop pulling spams out of the spam_history table that
    # are ready to send. But we must be careful about concurrency race conditions
    # because the process of sending a spam can take many hours, and the spam
    # sender daemon gets run every hour or so, and the web server could easily get restarted
    # in the middle of this operation.
    while { 1 } {

	ns_log Notice "send_scheduled_spam_messages: checking spam_history queue"

	ns_db dml $db "begin transaction" 

	# Get a list of all spams which have current or past-due deadlines,and
	# which have not already been processed.
	set selection [ns_db select $db "select spam_id, creation_user, from_address, body_plain, body_html, body_aol, title, user_class_query, user_class_description, send_date, status, last_user_id_sent, template_p from spam_history
	where send_date <= sysdate 
	and (status = 'unsent' or status = 'interrupted')
	order by send_date
	for update"]

	# If no more spams are pending, we can quit for now
	if {[ns_db getrow $db $selection] == 0} {
	    ns_db dml $db "end transaction"
	    ns_db releasehandle $db 
	    ns_db releasehandle $db2
	    return 
	}

	set_variables_after_query
	ns_db flush $db

	ns_log Notice "send_scheduled_spam_messages: got spam_id=$spam_id, from_address=$from_address, title=$title"

	# If the spam daemon was interrutped while sending, we can resume at the last
	# user_id sent to.
	if { [string compare $status "interrupted"] == 0 && ![empty_string_p $last_user_id_sent] } { 
	    set resume_sending_clause "	and users.user_id > $last_user_id_sent "
	} else {
	    set resume_sending_clause "	"
	}

	# Mark this spam as being processed. Let's try to be very careful not to send 
	# mail to any user more than once.
	ns_db dml $db "update spam_history set status = 'sending', begin_send_time = sysdate where spam_id = $spam_id"
	ns_log Notice "spam_daemon: sending spam_id $spam_id '$user_class_description'"

	ns_db dml $db "end transaction"	

	# These hold any extra mail headers we want to send with each message.
	# Headers for HTML mail
	set msg_html_headers [ns_set create]
	ns_set update $msg_html_headers "Mime-Version" "1.0"
	ns_set update $msg_html_headers "Content-Type" "multipart/alternative; boundary=\"[spam_mime_boundary]\""


	# Headers for AOL mail
	set msg_aol_headers [ns_set create]
	ns_set update $msg_aol_headers "Content-type" "text/html; charset=\"iso-8859-1\""

	# Headers for plain text mail
	set msg_plain_headers [ns_set create]

	################
	# For each spam, get the list of interested users, and send mail.

	# standard query but make sure that we don't send to dont_spam_me_p or
	# deleted_p users
	regsub -nocase "^select" $user_class_query "select email_type, " user_class_query_plus_email_type
	set query "$user_class_query_plus_email_type
	$resume_sending_clause
	order by users.user_id"

	# NOTE: there is a magic (kludge) here to access user_preferences for each user:
	# The users_spammable view
	# now contains a join with users_preferences.*, so that the users_preference.email_type
	# can be selected.

	ns_log Notice "spam user class query: $query"

	if {$use_bulkmail_p == 1} {
	    set bulkmail_id [bulkmail_begin $db $creation_user "spam_id $spam_id"]
	}

	set selection [ns_db select $db $query]
	# query sets user_id for each interested user

	# more accurate flow rate if we set this as the start time, because above query takes
	# a couple minutes sometimes
	ns_db dml $db2 "update spam_history set begin_send_time = sysdate where spam_id = $spam_id"

	set send_count 0

	#Get site-wide removal blurb
	set txt_removal_blurb  [ad_removal_blurb "" "txt"]
	set html_removal_blurb [ad_removal_blurb "" "htm"]
	set aol_removal_blurb  [ad_removal_blurb "" "aol"]

	# Make a quoted printable encoding of the content plus removal blurb
	regsub -all "\r" $body_html "" full_html_msg
	append full_html_msg $html_removal_blurb
	set qp_body_html [spam_encode_quoted_printable $full_html_msg]

	regsub -all "\r" $body_plain "" body_plain_full
	append body_plain_full $txt_removal_blurb

	while { [ns_db getrow $db $selection] } {

	    set_variables_after_query

	    # remove spaces from email address (since user registration doesn't currently do this)
	    # since these are almost certainly bogus
	    regsub -all " " $email "" email_stripped
	    set email $email_stripped

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
		    # The '--' strings really matter here.
		    # The MIME boundary delimiter is a '--' sequence, but it is hard to tell when
		    # looking at code which has a mime boundary starting with '---...'
		    set message_body_template "--[spam_mime_boundary]
Content-Type: text/plain; charset=\"us-ascii\"
Content-Transfer-Encoding: 7bit

$body_plain_full

--[spam_mime_boundary]
Content-Type: text/html; charset=\"iso-8859-1\"
Content-Transfer-Encoding: quoted-printable
Content-Base: [spam_content_base]

$qp_body_html
--[spam_mime_boundary]--
"
		}
		"text/aol-html" { 
		    set extra_headers [ns_set copy $msg_aol_headers]
		    set message_body_template "$body_aol\n$aol_removal_blurb"
		}
		default {
		    set extra_headers [ns_set copy $msg_plain_headers]
		    set message_body_template "$body_plain\n$txt_removal_blurb"
                }
	    }

	    if {[string match $template_p "t"]} {
		if {[catch {
		    set message_body [subst $message_body_template]
		    set title [subst $title]
		} errmsg]} {
		    ns_log Error "Tcl evaluator error in subst call for spam_id $spam_id: $errmsg\nAborting the sending of this spam."
		    break
		}
	     } else {
		 set message_body $message_body_template
	     }

	    ns_log Notice "Sending spam to $email, \"$title\""
	    set failed_p 0
	    if {$spam_email_sending_enabled_p == 0} {
		ns_log Notice "** spam disabled:  spam to $user_id, $email, \"$title\""
		ns_db releasehandle $db 
		ns_db releasehandle $db2
		return
	    } else {
		if {$use_bulkmail_p == 1} {
		    # The sender address is overwritten automatically by the bulkmailer
		    bulkmail_send $bulkmail_id $user_id $email $from_address $title $message_body {} $extra_headers
		} else {
		    if { [catch {ns_sendmail $email $from_address $title $message_body $extra_headers} errmsg] } {
			ns_log Warning "ns_sendmail failed: $errmsg"
			set failed_p 1
		    }
		}
	    }

	    if !$failed_p {
		incr send_count

		# we log this every N sends, to keep the overhead down
		if {[expr $send_count % $logging_frequency] == 0} {
		    ns_db dml $db2 "update spam_history 
		    set last_user_id_sent = $user_id,
		    n_sent = n_sent + $logging_frequency where spam_id = $spam_id"
		}
	    }
	}

	if {$use_bulkmail_p == 1} {
	    bulkmail_end $db $bulkmail_id
	}
	ns_db dml $db2 "update spam_history set
	n_sent = n_sent + [expr $send_count % $logging_frequency] where spam_id = $spam_id"

	ns_db dml $db "update spam_history set status = 'sent', finish_send_time = sysdate where spam_id = $spam_id"
	ns_log Notice "moving spam_id $spam_id to \"sent\" state"
    }

    ns_db releasehandle $db 
    ns_db releasehandle $db2
}




################################################################
# Load up table of default email types from config .ini file

proc config_default_email_types {} {
    set db  [ns_db gethandle]
    ns_db dml $db "delete from default_email_types"
    set email_types [ad_parameter EmailTypes "spam"]
    ns_log Notice "email_types = $email_types"
    foreach entry $email_types {
	set pattern [lindex $entry 0]
	set mime_type [lindex $entry 1]
	ns_db dml $db "insert into default_email_types (pattern, mail_type) values ('[DoubleApos $pattern]', '[DoubleApos $mime_type]')"
    }
    ns_db releasehandle $db 
}

ad_schedule_proc -once t 5 config_default_email_types


# Any spam which is in the "sending" state when the server is restarted was
# clearly interrupted in the middle of a send job. So we move it to the 'interrupted'
# state (which is effectively just another name for the 'unsent' state). The 
# next thread which calls send_scheduled_spam_messages will then grab the
# lock on it (so to speak), by moving it to the sending state, and start 
# resume emails at the last user_id which was sent to. 
#

proc flag_interrupted_spams {} {
    set db [ns_db gethandle]
    set selection [ns_db select $db "select * from spam_history where status = 'sending'"]
    ns_log Notice "Checking for spam jobs which were left in the 'sending' state"
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_log Notice "moving spam $spam_id, $creation_date '$title' to interrupted state"
    }
    ns_db dml $db "update spam_history set status = 'interrupted' where status = 'sending'"
    ns_db releasehandle $db 
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

proc check_spam_drop_zone {db db2} {
    set date [database_to_tcl_string $db "select to_char(sysdate,'MM-DD-YYYY') from dual"]
    set pretty_date [database_to_tcl_string $db "select to_char(sysdate,'MM/DD/YYYY') from dual"]

    # outer loop - iterate over daily_spam_files table looking for descriptors of
    # files in the drop zone.
    set selection [ns_db select $db "select file_prefix, from_address, subject, target_user_class_id, template_p, user_class_description, period
    from daily_spam_files"]
    
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	# This should be improved to use date functions to pick nth day of week, month, or year,
	# so people can schedule a spam every Monday or on the 10th of each month
	switch $period {
	    daily { set period_days 1 }
	    weekly { set period_days 7 }
	    monthly { set period_days 30 }
	    yearly { set period_days 365 }
	}

	# Check if a spam has already been queued for this file prefix and today's date or period
	set already_queued [database_to_tcl_string $db2 "select count(spam_id) from spam_history 
	where pathname = '[set file_prefix]'
	and (sysdate - send_date) < $period_days
	"]

	if { $already_queued > 0 } {
	    continue
	} else {

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
		set query [ad_user_class_query $set_args]
		regsub {from users} $query {from users_spammable users} query

		ns_ora clob_dml $db2 "insert into spam_history
		(spam_id, template_p, from_address, title, body_plain, body_html, body_aol, user_class_description, user_class_query, send_date, creation_date, creation_user, status, creation_ip_address,pathname)
		values
		(spam_id_sequence.nextval, '$template_p', '[DoubleApos $from_address]', '[DoubleApos $subject_x]', empty_clob(),empty_clob(),empty_clob(), '[DoubleApos $user_class_description]', [ns_dbquotevalue $query], sysdate, sysdate, $system_user, 'unsent', '0.0.0.0', [ns_dbquotevalue $file_prefix])
		returning body_plain, body_html, body_aol into :1, :2, :3" $file_plain $file_html $file_aol 

		ns_log Notice "Daily spam queued for \"$file_prefix\" from $dropfile_path_plain"
	    }
	}
    }
}


# returns a string containing of html form inputs fields for adding user to spam groups
proc spam_subscriptions_form_html { db newsletter_category_name user_id } {
    set query "select user_groups.group_id, newsletter_info.short_description, user_groups.group_name, user_group_map.user_id as member_p 
    from user_groups, user_group_map, newsletter_info
    where upper(group_type) = upper('newsletter')
    and user_group_map.user_id(+) = $user_id
    and user_group_map.group_id(+) = user_groups.group_id
    and newsletter_info.group_id = user_groups.group_id
    and newsletter_info.category = '[DoubleApos $newsletter_category_name]'
    order by group_name"

    set result ""

    set selection  [ns_db select $db $query]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if {[empty_string_p $member_p]} {
	    set checked ""
	} else {
	    set checked "checked"
	}
	append result "<tr><td align=left><input type=checkbox $checked name=spam_group_id value=\"$group_id\">$group_name</td><td>$short_description</td></tr>\n"
    }
                  
    return $result
}


proc spam_guess_email_type_preference {db user_id} {
    return [database_to_tcl_string "select guess_user_email_type($user_id) from dual"]
}




# Produces an html form fragment giving a user the default choice of newsletters to sign 
# up for. Uses the .ini parameter spam/DefaultNewsletterGroups, a list of group id numbers
# of the newsletter groups we use as the default choices for new users.
proc spam_default_newsletter_signup_html {db {checked "checked"}} {
    set default_newsletter_groups [ad_parameter "DefaultNewsletterGroups" "spam"]
    set html_fragment ""
    if {[llength $default_newsletter_groups] > 0} {
	set selection [ns_db select $db "select user_groups.group_id, group_name,
	short_description, long_description, category
	from user_groups, newsletter_info
	where user_groups.group_id in ($default_newsletter_groups)
	and user_groups.group_id = newsletter_info.group_id"]
	
	while { [ns_db getrow $db $selection] } {
	    set_variables_after_query
	    # get the info associated with each newsletter group
	    append html_fragment "<input $checked type=checkbox name=\"join_newsletter\" value=\"$group_id\"> <b>$group_name</b><br>&nbsp;&nbsp;&nbsp;&nbsp; $short_description<br>"
	}

    }
    return $html_fragment
}    
    

proc_doc spam_sanitize_filename {filename} "Remove any pathname metachars from a filename, allow only a very clean set of characters" {
    regsub -all {[^A-aZ-z0-9._-]} $filename "_" file_clean
    regsub -all {[.]+} $file_clean "." file_clean_1
    return $file_clean_1
}


util_report_successful_library_load
