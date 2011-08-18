# $Id: gift-certificate-edit.tcl,v 3.0.4.1 2000/04/28 15:08:38 carsten Exp $
set_the_usual_form_variables
# user_id, gift_certificate_id, expires

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

ns_db dml $db "update ec_gift_certificates
set expires=sysdate, last_modified=sysdate, last_modifying_user=$customer_service_rep, 
modified_ip_address='[DoubleApos [ns_conn peeraddr]]' where gift_certificate_id=$gift_certificate_id"

ad_returnredirect "gift-certificates.tcl?[export_url_vars user_id]"
