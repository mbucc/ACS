# $Id: q-and-a-thread-unalert.tcl,v 1.1.2.2 2000/04/28 15:09:43 carsten Exp $
set_the_usual_form_variables
# thread_id

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    set return_url "/bboard/q-and-a-thread-alert.tcl?[export_url_vars thread_id]"
    ad_returnredirect "/register/index.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

ns_db dml $db "delete from bboard_thread_email_alerts
where thread_id='$thread_id'
   and user_id=$user_id"

ad_returnredirect "q-and-a-fetch-msg.tcl?msg_id=[ns_urlencode $thread_id]"

