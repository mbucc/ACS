# $Id: order.tcl,v 3.0.4.1 2000/04/28 15:10:01 carsten Exp $
set_the_usual_form_variables
# order_id
# possibly usca_p

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# user session tracking
set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]

ec_create_new_session_if_necessary [export_url_vars order_id]


ec_log_user_as_user_id_for_this_session

set order_summary "<pre>
Order #:
$order_id

Status:
[ec_order_status $db $order_id]
</pre>

[ec_order_summary_for_customer $db $order_id $user_id "t"]
"

ad_return_template