# $Id: gift-certificate-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:38 carsten Exp $
set_the_usual_form_variables
# user_id, amount, expires

set expires_to_insert [ec_decode $expires "" "null" $expires]

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# put a record into ec_gift_certificates
# and add the amount to the user's gift certificate account

ns_db dml $db "insert into ec_gift_certificates
(gift_certificate_id, user_id, amount, expires, issue_date, issued_by, gift_certificate_state, last_modified, last_modifying_user, modified_ip_address)
values
(ec_gift_cert_id_sequence.nextval, $user_id, $amount, $expires_to_insert, sysdate, $customer_service_rep, 'authorized', sysdate, $customer_service_rep, '[DoubleApos [ns_conn peeraddr]]')
"

ad_returnredirect "gift-certificates.tcl?[export_url_vars user_id]"
