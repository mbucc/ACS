# $Id: approve-toggle.tcl,v 3.0.4.1 2000/04/28 15:08:58 carsten Exp $
#
# jkoontz@arsdigita.com July 22 1999
#
# Toggles a user_class between approved and unapproved

set_the_usual_form_variables
# user_class_id user_class_approved_p user_id

# we need them to be logged in
set admin_user_id [ad_verify_and_get_user_id]

if {$admin_user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

ns_db dml $db "update ec_user_class_user_map
set user_class_approved_p=[ec_decode $user_class_approved_p "t" "'f'" "'t'"], last_modified=sysdate, last_modifying_user=$admin_user_id, modified_ip_address='[DoubleApos [ns_conn peeraddr]]'
where user_id=$user_id and user_class_id=$user_class_id"

ad_returnredirect "members.tcl?[export_url_vars user_class_id]"
