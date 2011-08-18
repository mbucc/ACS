# $Id: edit-ad.tcl,v 3.1.2.1 2000/04/28 15:10:31 carsten Exp $
set_form_variables
set_form_variables_string_trim_DoubleAposQQ

# domain_id


#check for the user cookie
set user_id [ad_get_user_id]

if {$user_id != 0} {
    ad_returnredirect "edit-ad-2.tcl?[export_url_vars domain_id user_id]"
} else {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode /gc/edit-ad-2.tcl?domain_id=$domain_id]
}


