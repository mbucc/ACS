# /www/ticket/ticket-watch.tcl
ad_page_contract {
    Adds an entry to the email alerts table (as long as one doesn't 
    already exist).

    @param msg_id the ticket to add the alert on
    @param return_url where to go when finished

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id ticket-watch.tcl,v 3.1.6.5 2000/07/21 04:04:36 ron Exp
} {
    msg_id:integer,notnull 
    {return_url ""}
}

# -----------------------------------------------------------------------------
 
set user_id [ad_verify_and_get_user_id]

if {[catch {db_dml alert_insert "
insert into ticket_email_alerts 
(alert_id, user_id, msg_id, domain_id, project_id, established) 
select ticket_alert_id_sequence.nextval, 
       :user_id, 
       :msg_id, 
       NULL, 
       NULL, 
       sysdate 
from   dual 
where  not exists (select 1 from ticket_email_alerts 
                   where  user_id = :user_id 
                   and    msg_id = :msg_id)"} errmsg]} {

    ad_return_complaint 1 "<LI> Unable to complete your request. Database error: <pre>$errmsg</err>"
    return
}

ad_returnredirect $return_url  

