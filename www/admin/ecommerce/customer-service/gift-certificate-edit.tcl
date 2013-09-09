# gift-certificate-edit.tcl

ad_page_contract { 
    @param user_id
    @param gift_certificate_id
    @param expires

    @author
    @creation-date
    @cvs-id gift-certificate-edit.tcl,v 3.1.6.4 2000/07/21 03:56:54 ron Exp
} {
    user_id
    gift_certificate_id
    expires
}




set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}


set address [ns_conn peeraddr]
db_dml update_ec_gc_info "update ec_gift_certificates
set expires=sysdate, last_modified=sysdate, last_modifying_user=:customer_service_rep, 
modified_ip_address= :address
where gift_certificate_id=:gift_certificate_id"
db_release_unused_handles
ad_returnredirect "gift-certificates.tcl?[export_url_vars user_id]"
