# /www/ticket/ticket-update-assignment.tcl
ad_page_contract {
    Updates ticket assignments.  Instead of the old version that took
    arbitrary numbers of updates, we now take only one.  (Since that's
    the only way this page was ever used.)

    @param return_url where to go next
    @param assignee the lucky guy or gal who gets to fix the problem
    @param one_line
    @param force
    @param msg_id the ID of the ticket whose assignments we are changing

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id ticket-update-assignment.tcl,v 3.8.2.6 2000/07/21 04:04:35 ron Exp

} {
    return_url:notnull
    assignee:integer
    project_id:integer
    domain_id:integer
    {one_line ""}
    {force "none"}
    msg_id:integer,notnull
}

# -----------------------------------------------------------------------------

 
set user_id [ad_verify_and_get_user_id]

# make a list of the changed assignments.



if { [empty_string_p $assignee] } { 
    if { [string compare $force remove] != 0} { 
        ReturnHeaders
        ns_write "
    [ad_header "Ticket tracker: Remove users from \#$msg_id -  $one_line"]
    <h1>Confirm action</h1>
    [ad_context_bar_ws_or_index [list $return_url "Ticket Tracker"] "Confirm"]
    <hr>
    <form action=\"[ns_conn url]\" method=POST>
    <font size=+1>Remove all assigned users from \"\#$msg_id - $one_line\"</font> 
    <blockquote>
    <input type=submit value=\"Confirm\">
    </blockquote>
    [export_ns_set_vars form force]
    <input type=hidden name=force value=remove>
    </form>[ad_footer]"
        return
    } else { 
        db_dml assignment_delete "
	delete ticket_issue_assignments where msg_id = :msg_id" 
        ad_returnredirect $return_url 
        return
    }
}

# now generate the update statements

db_transaction { 
    set already_assigned_p [db_string already_assigned_p "
    select nvl((select 1
               from ticket_issue_assignments tia 
               where tia.msg_id = :msg_id 
               and tia.user_id = :assignee),0) from dual"]

    if {! $already_assigned_p} {
        db_dml assignment_insert "
	insert into ticket_issue_assignments
	(msg_id, user_id, purpose, active_p) 
	values
	( :msg_id, :assignee, NULL, 't')"

    }
} on_error { 
    ad_return_complaint 1 "<LI>Database failure performing update <pre>$errmsg</pre>"
    return -code return
}

if { $already_assigned_p } { 
    ad_return_complaint 1 "<LI>The user you are adding is already assigned to this ticket."
    return
}

# Grab location now, since it's not available after we close the connection.

set my_location [ns_conn location]

ad_returnredirect $return_url 
ns_conn close

#
# Now send mail 
#

set description [db_string email_desc "
select content from general_comments gc, ticket_issues ti 
where ti.comment_id = gc.comment_id and ti.msg_id = :msg_id" ]

set assignor [db_string assignor_name "
select first_names || ' ' || last_name from users 
where user_id = :user_id" ]

set extra_headers [ns_set create] 

db_foreach email_recipients "
select email from users_alertable 
where user_id = :assignee" {
    
    ns_set update $extra_headers "Reply-To" [ticket_reply_email_addr $msg_id $assignee] 
    
    if { [catch {
        ns_sendmail [ticket_mail_send $email] \
            [ticket_reply_email_addr] \
            "Ticket assignment to \#$msg_id - $one_line" \
            "$assignor has assigned you to ticket:\n\n\#$msg_id $one_line\nDESCRIPTION:\n\n[ns_striphtml $description]\n\nManage via $my_location/ticket/issue-view.tcl?msg_id=$msg_id\n" \
            $extra_headers
    } errmsg ] } { 
        ns_log notice "TicketMail: failed to send notifies to $email on msg_id $msg_id: $errmsg"
    }
}

#for testing.
#ReturnHeaders
#ns_write "[ad_header $msg_id]$msg_id $description $email [ad_footer]"

