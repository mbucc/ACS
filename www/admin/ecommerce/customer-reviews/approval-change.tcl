# $Id: approval-change.tcl,v 3.0.4.1 2000/04/28 15:08:37 carsten Exp $
set_the_usual_form_variables
# approved_p, comment_id,
# possibly return_url

set user_id [ad_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]
ns_db dml $db "update ec_product_comments set 
approved_p='$approved_p',
last_modified = sysdate,
last_modifying_user = $user_id,
modified_ip_address = '[ns_conn peeraddr]'
where comment_id=$comment_id"

if { ![info exists return_url] } {
    ad_returnredirect index.tcl
} else {
    ad_returnredirect $return_url
}
