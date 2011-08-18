# $Id: void-2.tcl,v 3.0.4.1 2000/04/28 15:08:45 carsten Exp $
set_the_usual_form_variables
# order_id, reason_for_void

# we need them to be logged in
set customer_service_rep [ad_verify_and_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

ns_db dml $db "update ec_orders set order_state='void',reason_for_void='$QQreason_for_void',voided_by=$customer_service_rep, voided_date=sysdate where order_id=$order_id"

ns_db dml $db "update ec_items set item_state='void', voided_by=$customer_service_rep where order_id=$order_id"

# reinstate gift certificates
ns_db dml $db "declare begin ec_reinst_gift_cert_on_order($order_id); end;"

ns_db dml $db "end transaction"

ad_returnredirect "one.tcl?[export_url_vars order_id]"
