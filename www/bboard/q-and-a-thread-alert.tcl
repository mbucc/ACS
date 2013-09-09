# /www/bboard/q-and-a-thread-alert.tcl
ad_page_contract {
    adds an alert for a bboard thread
    
    @cvs-id q-and-a-thread-alert.tcl,v 3.2.2.4 2000/12/19 01:15:50 kevin Exp
} {
    thread_id
}

# -----------------------------------------------------------------------------

page_validation {
    bboard_validate_msg_id $thread_id
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

db_transaction {
set num_alerts [db_string num_alerts "
select count(*) from bboard_thread_email_alerts
where thread_id = :thread_id
and   user_id = :user_id"]

if { $num_alerts == 0 } {
    db_dml thread_alert_insert "
    insert into bboard_thread_email_alerts (thread_id, user_id)
    values (:thread_id, :user_id)"
}
}

ad_returnredirect "q-and-a-fetch-msg.tcl?msg_id=[ns_urlencode $thread_id]"

