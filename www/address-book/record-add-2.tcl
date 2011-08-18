# $Id: record-add-2.tcl,v 3.0 2000/02/06 02:44:21 ron Exp $
# File:     /address-book/record-add-2.tcl
# Date:     12/24/99
# Contact:  teadams@arsdigita.com, tarik@arsdigita.com
# Purpose:  adds an address book record
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# address_book_id, first_names, last_name, email, email2, line1, line2, city, usps_abbrev, zip_code, phone_home, phone_work, phone_cell, phone_other, country, birthmonth, birthday, birthyear, days_in_advance_to_remind, days_in_advance_to_remind_2, notes
# maybe return_url

if { ![info exists return_url] } {
    set return_url "index.tcl?[export_url_scope_vars]"
}

ad_scope_error_check user

set db [ns_db gethandle]
ad_scope_authorize $db $scope none group_admin user

set column_list [list address_book_id first_names last_name email email2 line1 line2 city usps_abbrev zip_code phone_home phone_work phone_cell phone_other country birthmonth birthday birthyear days_in_advance_to_remind days_in_advance_to_remind_2 notes]

foreach column $column_list {
    if [info exists QQ$column] {
	lappend QQvalues_list "[set QQ$column]"
	lappend final_column_list $column
    }
}

ad_dbclick_check_dml $db address_book address_book_id $address_book_id $return_url "
insert into address_book 
([join $final_column_list ,], [ad_scope_cols_sql]) 
values 
('[join $QQvalues_list "','"]', [ad_scope_vals_sql])
"


