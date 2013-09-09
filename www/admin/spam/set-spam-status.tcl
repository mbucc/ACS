# www/admin/spam/set-spam-status.tcl

ad_page_contract {

 Force spam into a specific state.

    @param spam_id the id of the message
    @param status the state of the spam message (status column in spam_history)
    @author hqm@arsdigita.com
    @cvs-id set-spam-status.tcl,v 3.2.6.4 2000/07/21 03:58:01 ron Exp
} {
  spam_id:integer
  status
}

db_dml set_spam_status "update spam_history set status = :status where spam_id = :spam_id"

ad_returnredirect "old.tcl?spam_id=$spam_id"

