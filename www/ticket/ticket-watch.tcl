# $Id: ticket-watch.tcl,v 3.0.4.1 2000/04/28 15:11:36 carsten Exp $
#
#  add an entry to ticket_email_alerts.
#

ad_page_variables {msg_id return_url} 

set db [ns_db gethandle] 
set user_id [ad_get_user_id]

if {[catch {ns_db dml $db "insert into ticket_email_alerts (
   alert_id, user_id, msg_id, domain_id, project_id, established
   ) select ticket_alert_id_sequence.nextval, $user_id, $msg_id, null, null, sysdate from dual where not exists (select 1 from ticket_email_alerts where user_id = $user_id and msg_id = $msg_id)"} errmsg]} {
    ad_return_complaint 1 "<LI> Unable to complete your request. Database error: <pre>$errmsg</err>"
    return
}

ad_returnredirect $return_url  

