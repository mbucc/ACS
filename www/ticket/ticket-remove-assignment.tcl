# $Id: ticket-remove-assignment.tcl,v 3.1.4.1 2000/04/28 15:11:35 carsten Exp $
ad_page_variables {
    return_url 
    msg_id
    user_id
    {one_line {}}
}

set db [ns_db gethandle] 
set my_user_id [ad_get_user_id]

if {[empty_string_p $msg_id]} { 
    ad_return_complaint 1 "<LI>I cannot remove a user without a ticket ID."
    return
}    

ns_db dml $db "delete ticket_issue_assignments where msg_id = $msg_id and user_id = $user_id"
ad_returnredirect $return_url 
return







