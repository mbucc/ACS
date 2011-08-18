# $Id: ticket-update-assignment.tcl,v 3.3.2.2 2000/04/28 15:11:35 carsten Exp $
ad_page_variables {
    return_url 
    {one_line {}}
    {force {none}}
    {msg_id {}}}

set form [ns_getform]

set db [ns_db gethandle] 
set my_user_id [ad_get_user_id]

if {[empty_string_p $form]} { 
    ad_return_complaint 1 "<LI>You did not send me any information"
    return
}

set size [ns_set size $form]

# make a list of the changed assignments.

if {[empty_string_p $msg_id]} { 
    ad_return_complaint 1 "<LI>I cannot assign users without a ticket ID."
    return
}    

set bad 0
set badstr {}
set users {}

for  {set i 0} {$i < $size} { incr i} {
    set new_user_id [ns_set value $form $i]

    if {![empty_string_p $new_user_id]} {
        if {[regexp {^a_(([0-9]+)_([0-9]+))_([0-9]*)} [ns_set key $form $i] match pg project_id domain_id user_id]} { 
            lappend users $new_user_id
        }
    }
}

if { [empty_string_p $users] } { 
    if { [string compare $force remove] != 0} { 
        ReturnHeaders
        ns_write "
    [ad_header "Ticket tracker: Remove users from \#$msg_id -  $one_line"]
    <h1>Confirm action</h1>
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
        ns_db dml $db "delete ticket_issue_assignments where msg_id = $msg_id"
        ad_returnredirect $return_url 
        return
    }
}

# now generate the update statements

with_transaction $db { 
    # build a list of new assignments 
    # validate the user_ids exist here as well
    set new_users [database_to_tcl_list $db "select u.user_id 
    from users u 
    where not exists ( 
       select 1
       from ticket_issue_assignments tia 
       where tia.msg_id = $msg_id 
         and tia.user_id in ([join $users {,}])
         and tia.user_id = u.user_id)
      and u.user_id in ([join $users {,}])"]

    if {![empty_string_p $new_users]} { 
        ns_db dml $db "insert into ticket_issue_assignments(msg_id, user_id, purpose, active_p) select $msg_id, u.user_id,null,'t' from users u where user_id in ([join $new_users {,}])"
    }
} { 
    ad_return_complaint 1 "<LI>Database failure performing update <pre>$errmsg</pre>"
    return -code return
}

if {[empty_string_p $new_users]} { 
    ad_return_complaint 1 "<LI>The user You are adding is already assigned to this ticket."
    return
}

# Grab location now, since it's not available after we close the connection.
set location [ns_conn location]

ad_returnredirect $return_url 
ns_conn close

#
# Now send mail 
#

set description [database_to_tcl_string $db "select content from general_comments gc, ticket_issues ti where ti.comment_id = gc.comment_id and ti.msg_id = $msg_id"]

set assignor [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $my_user_id"]

set extra_headers [ns_set create] 

set selection [ns_db select $db "select email, user_id from users_alertable where user_id in ([join $new_users {,}])"]


while {[ns_db getrow $db $selection]} { 
    set_variables_after_query
    
    ns_set update $extra_headers "Reply-To" [ticket_reply_email_addr $msg_id $user_id] 
    
    if { [catch {
        ns_sendmail [ticket_mail_send $email] \
            [ticket_reply_email_addr] \
            "Ticket assignment to \#$msg_id - $one_line" \
            "$assignor has assigned you to ticket:\n\n\#$msg_id $one_line\nDESCRIPTION:\n\n[ns_striphtml $description]\n\nManage via $location/ticket/issue-view.tcl?msg_id=$msg_id\n" \
            $extra_headers
    } errmsg ] } { 
        ns_log notice "TicketMail: failed to send notifies to $email on msg_id $msg_id: $errmsg"
    }
}

#for testing.
#ReturnHeaders
#ns_write "[ad_header $msg_id]$msg_id $description $email [ad_footer]"
