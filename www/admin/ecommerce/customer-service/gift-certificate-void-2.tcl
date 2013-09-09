# gift-certificate-void-2.tcl

ad_page_contract {  
    @param gift_certificate_id
    @param reason_for_void
   
    @author
    @creation-date
    @cvs-id gift-certificate-void-2.tcl,v 3.1.6.5 2000/08/18 21:46:54 stevenp Exp
} {
    gift_certificate_id
    reason_for_void
}

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ad_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}



db_dml update_void_gift_c "update ec_gift_certificates set gift_certificate_state='void', voided_date=sysdate, voided_by=:customer_service_rep, reason_for_void=:reason_for_void where gift_certificate_id=:gift_certificate_id"

set user_id [db_string get_the_user_id "select user_id from ec_gift_certificates where gift_certificate_id=:gift_certificate_id"]
db_release_unused_handles
ad_returnredirect "gift-certificates.tcl?[export_url_vars user_id]"
