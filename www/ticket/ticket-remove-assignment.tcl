# /www/ticket/ticket-remove-assignment.tcl
ad_page_contract {
    Remove a user assignmento from a ticket

    @param return_url where to go afterwards
    @param msg_id the ID for the ticket
    @param user_id the ID for the user

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id ticket-remove-assignment.tcl,v 3.3.2.4 2000/07/21 04:04:34 ron Exp
} {
    return_url:notnull
    msg_id:integer,notnull
    user_id:integer,notnull
}

# -----------------------------------------------------------------------------

db_dml ticket_assignment_remove "
delete ticket_issue_assignments 
where msg_id = :msg_id 
and user_id = :user_id" 

ad_returnredirect $return_url 


