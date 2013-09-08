# /www/bboard/q-and-a-thread-unalert.tcl
ad_page_contract {
    Removes an alert on a thread.

    @param thread_id the thread the alert is on

    @cvs-id q-and-a-thread-unalert.tcl,v 3.3.2.4 2000/07/21 03:58:49 ron Exp
} {
    thread_id
}

# -----------------------------------------------------------------------------

page_validation {
    bboard_validate_msg_id $thread_id
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


db_dml thread_alert_delet "
delete from bboard_thread_email_alerts
where thread_id = :thread_id
and   user_id = :user_id"

ad_returnredirect "q-and-a-fetch-msg.tcl?msg_id=[ns_urlencode $thread_id]"

