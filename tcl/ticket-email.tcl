###########################################################
#
# Set a daemon to nag users who have open tickets which are
# past their deadlines

proc notify_overdue_tickets {} {
    # days between notifcations
    set nag_period 7  
    # We do *not* want bounced messages going to the ticket handler script
    set maintainer_email [ad_system_owner]
    set url "[ad_url]/ticket"


    set db_pools [ns_db gethandle subquery 2]
    set db [lindex $db_pools 0]
    set db2 [lindex $db_pools 1]

    set notified_msg_ids {}

    # loop over each user who has any assigned tickets, 
    # finding all past-deadline tickets
    set selection [ns_db select $db "select distinct ua.user_id, ua.email 
    from users_alertable ua, ticket_issue_assignments, users_preferences
    where ticket_issue_assignments.user_id = ua.user_id
    and ua.user_id = users_preferences.user_id
    and users_preferences.dont_spam_me_p = 'f'
    and ticket_issue_assignments.active_p = 't'"]
    
    if {[empty_string_p $selection]} {
	return
    }

    while { [ns_db getrow $db $selection] } { 
	# For each user, find all past-due tickets, and make a summary message
	set msgs ""
	set_variables_after_query
	
	set sub_selection [ns_db select $db2 "select
	ti.msg_id, ti.one_line as summary,
	to_char(ti.modification_time, 'mm/dd/yy') as modification,
	to_char(ti.posting_time, 'mm/dd/yy') as creation,
	to_char(ti.deadline, 'mm/dd/yy') as deadline
	from ticket_issues ti, ticket_issue_assignments ta 
	where
	ti.msg_id = ta.msg_id 
	and ta.user_id = $user_id
	and ta.active_p = 't' 
	and close_date is null
	and (last_notification is null or (sysdate - last_notification) > 7)
	and deadline is not null and deadline < sysdate"] 
	
	while { [ns_db getrow $db2 $sub_selection] } { 
	    set_variables_after_subquery
	    append msgs "Issue #$msg_id $summary\ndeadline was $deadline, created $creation, last modified $modification\n$url/issue-view.tcl?msg_id=$msg_id\n\n"
	    lappend notified_msg_ids $msg_id
	}
    
	if {$msgs != ""} {
	    set msgbody "The following issues assigned to you are still open and past their deadline:"
	    append msgbody "\n\n$msgs"
	    
	    set extra_headers [ns_set create] 
	    ns_set update $extra_headers "Reply-to" $maintainer_email
	    ns_sendmail $email $maintainer_email \
		    "Notification: Past due issues assigned to you" \
		    $msgbody $extra_headers 
	    ns_log Notice "sending ticket deadline alert email to $user_id $email"

	}
    }
    # update timestamp for these messages as having been notified 
    if {[llength $notified_msg_ids] > 0} {
	ns_db dml $db "update ticket_issues set last_notification = sysdate where msg_id in ([join $notified_msg_ids {,}])"
    }

}

################################################################
# Scan for messages past deadline, and send alerts, once per day
#
# Notifications will only be sent once a week (as specified above)
# for a given ticket and user, but the queue is scanned daily for
# past-deadline tickets.

# Turned off for now.
ns_share -init {set overdue_ticket_alerts_installed 1} overdue_ticket_alerts_installed

if {!$overdue_ticket_alerts_installed} {
    set overdue_ticket_alerts_installed 1
    ns_log Notice "Scheduling notify_overdue_tickets"
    ns_schedule_daily -thread 3 30 notify_overdue_tickets
}


proc_doc ticket_email_process {db message} {
    Takes an incoming message and inserts a message into the 
    ticket system and notifies the relevant users.
} {
    
    # extract the headers 
    set from_addr ""
    set date ""
    set subject ""
    set msgtext ""
    set msg_id ""
    set reply_to ""

    # We want to grab headers for 
    # Date: Thu, 11 Mar 1999 01:42:24 -0500
    # From: Henry Minsky <hqm@ai.mit.edu>
    # Subject: Re: test message

    set parsed_msg [parse_email_message $message]

    set msgbody        [ns_set iget $parsed_msg "message_body"]
    set from_header    [ns_set iget $parsed_msg "from"]
    set subject [ns_set iget $parsed_msg "subject"]
    set date_header    [ns_set iget $parsed_msg "date"]
    set reply_to       [ns_set iget $parsed_msg "reply-to"]
    set to_header       [ns_set iget $parsed_msg "to"]
    set cc_header       [ns_set iget $parsed_msg "cc"]


    # look for address of form "Reply-To: foo@bar.com" since Reply-To if present is 
    # generally canonical.

    if {![regexp -nocase  "(\[A-Za-z0-9._/%&!-\]+@\[A-Za-z0-9.-\]+)" $reply_to from_line from_addr]} {
	regexp -nocase  "(\[^<\]*)<(\[A-Za-z0-9._/%&!-\]+@\[A-Za-z0-9.-\]+)" $reply_to from_line from_name from_addr
    }
    if {[empty_string_p $from_addr]} { 
        # if we did not get Reply-To resort to From for the users address.
        if {![regexp -nocase  "(\[A-Za-z0-9._/%&!-\]+@\[A-Za-z0-9.-\]+)" $from_header from_line from_addr]} {
            regexp -nocase  "(\[^<\]*)<(\[A-Za-z0-9._/%&!-\]+@\[A-Za-z0-9.-\]+)" $from_header from_line from_name from_addr
        }
    }

    if {[empty_string_p $from_addr]} {
	ns_log Notice "ticket_email_process could not parse from_addr from incoming message header: |$from_header| message=|$message|"
    }

    # Figure out the user_id and msg_id from the From info.
    set to_addr {}

    if {![regexp -nocase  "(\[A-Za-z0-9._/%&!-\]+@\[A-Za-z0-9.-\]+)" $to_header to_line to_addr]} {
	regexp -nocase  "(\[^<\]*)<(\[A-Za-z0-9._/%&!-\]+@\[A-Za-z0-9.-\]+)" $to_header to_line to_name to_addr
    }

    if {[empty_string_p $to_addr]} {
        # we bail here since w/o to_addr we do not know where to put it.
	ns_log Notice "EVIL MESSAGE ticket_email_process could not parse to_addr from incoming message header: |$to_header| message=|$message|"
	return
    }


    # figure out which ticket to book the comment on.
    set msg_id {} 
    set user_id {} 

    if {[regexp -nocase {ticket-([0-9]+)-([0-9]+)@} $to_addr match msg_id user_id]} { 
        # if we get anything back the user and msg exist
        set test [ns_db 0or1row $db "select msg_id from ticket_issues where msg_id = $msg_id"]
        if {[empty_string_p $test]} { 
            ns_log Notice "ticket_email_process could not find ticket $msg_id message=|$message|"
            return
        }
        set selection [ns_db 0or1row $db "select email from users where user_id = $user_id"]
        if {[empty_string_p $selection]} { 
            ns_log Notice "ticket_email_process could not find user_id $user_id message=|$message|"
            set user_id {} 
            set who $from_header
        }
    } else { 
        set who $from_header
    }

    
    
    # We need to have some user_id we can use as the author of the comment
    if {[empty_string_p $user_id]} {
        # We try to look up a user, based on their from address
	set user_id [database_to_tcl_string_or_null $db "select user_id from users where lower(email) = '[string tolower $from_addr]'"]
        
        if {[empty_string_p $user_id]} {
            # failing that we put it in as system but include the headers since 
            set user_id [database_to_tcl_string $db "select system_user_id from dual"]
            
            # Make a cleaner looking mail message, just reconstruct a couple of the headers
            append msgtext "From: <strong>[ns_quotehtml $from_header]</strong><br>"
            if {![empty_string_p $reply_to]} {
                append msgtext "Reply-to: <strong>[ns_quotehtml $reply_to]</strong><br>"
            }
            if {![empty_string_p $to_header]} {
                append msgtext "To: <strong>[ns_quotehtml $to_header]</strong><br>"
            }
            if {![empty_string_p $cc_header]} {
                append msgtext "CC: <strong>[ns_quotehtml $cc_header]</strong><br>"
            }
            if {![empty_string_p $date_header]} {
                append msgtext "Date: [ns_quotehtml $date_header]<br>"
            }

            append who " (unregistered saved as system user)"

            ns_log Notice "Could not find registered user $from_addr, using system user user_id=$user_id"

        }
        ns_log Notice "Could not find registered user for $to_addr, using user_id=$user_id"
    }

    if {[empty_string_p $subject]} { 
        set subject "To: [ns_quotehtml $to_header]"
    }

    append msgtext "<pre>$msgbody</pre>"

    with_transaction $db {
        set comment_id [database_to_tcl_string $db "select general_comment_id_sequence.nextval from dual"]
        ad_general_comment_add $db $comment_id {ticket_issues} $msg_id "ticket \#$msg_id" $msgtext $user_id "000.000.000.000" {t} {t} {}
    } { 
        ns_log Notice "Insert of comment failed $errmsg"
    }
    
    if {[catch {ticket_notify $db comment $msg_id $subject "Comment from $who\n\n$msgbody" $user_id} errmsg]} { 
        ns_log notice "Error notifying for Message $message on incoming ticket mail"
    }
    
    return {}
}
    

