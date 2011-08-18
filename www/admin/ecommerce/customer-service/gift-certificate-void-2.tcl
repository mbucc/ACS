# $Id: gift-certificate-void-2.tcl,v 3.0.4.1 2000/04/28 15:08:38 carsten Exp $
set_the_usual_form_variables
# gift_certificate_id, reason_for_void

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

ns_db dml $db "update ec_gift_certificates set gift_certificate_state='void', voided_date=sysdate, voided_by=$customer_service_rep, reason_for_void='[DoubleApos $reason_for_void]' where gift_certificate_id=$gift_certificate_id"

set user_id [database_to_tcl_string $db "select user_id from ec_gift_certificates where gift_certificate_id=$gift_certificate_id"]

ad_returnredirect "gift-certificates.tcl?[export_url_vars user_id]"