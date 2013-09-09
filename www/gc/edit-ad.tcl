# edit-ad.tcl

ad_page_contract {
    @cvs-id edit-ad.tcl,v 3.3.2.1 2000/07/21 22:40:31 mdetting Exp
} {
    domain_id:integer
}

#check for the user cookie
set user_id [ad_get_user_id]

if {$user_id != 0} {
    ad_returnredirect "edit-ad-2.tcl?[export_url_vars domain_id user_id]"
} else {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode /gc/edit-ad-2.tcl?domain_id=$domain_id]
}

