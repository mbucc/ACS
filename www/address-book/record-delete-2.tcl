# $Id: record-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:22 carsten Exp $
# File:     /address-book/record-delete-2.tcl
# Date:     12/24/99
# Contact:  teadams@arsdigita.com, tarik@arsdigita.com
# Purpose:  deletes address book record
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# yes_submit or no_submit
# address_book_id, maybe return_url

ad_scope_error_check user
set db [ns_db gethandle]
ad_scope_authorize $db $scope none group_admin user

if {[info exists no_submit]} {
    if {[info exists return_url]} {
	ad_returnredirect $return_url
	return
    } else {
	ad_returnredirect "records.tcl?[export_url_vars group_id scope]"
	return
    }
}

ns_db dml $db "delete from address_book where address_book_id=$address_book_id"


if [info exists return_url] {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "index.tcl?[export_url_scope_vars]"
}




