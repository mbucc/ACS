# $Id: payroll-edit-2.tcl,v 3.0.4.2 2000/04/28 15:11:06 carsten Exp $
#
# File: /www/intranet/employees/payroll-edit-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Saves payroll information
# 

ad_maybe_redirect_for_registration

set_form_variables
# dp stuff
# return_url (optional)

set user_id ${dp.im_employee_info.user_id}
set form_setid [ns_getform]

set db [ns_db gethandle]

# can the user make administrative changes to the user's salary information?
set user_admin_p [im_is_user_site_wide_or_intranet_admin $db $user_id]
if { !$user_admin_p } {
    ns_set delkey $form_setid dp.im_employee_info.salary
    ns_set delkey $form_setid dp.im_employee_info.salary_period
} else {
    ns_set put $form_setid dp.im_employee_info.salary_period [im_salary_period_input]
}

# This page is restricted to only site/intranet admins
if { $user_id != [ad_verify_and_get_user_id] && ![im_is_user_site_wide_or_intranet_admin $db] } {
    ad_returnredirect ../
    return
}

set exception_count 0
if { [catch {set birthdate [validate_ad_dateentrywidget birthdate birthdate [ns_conn form]]} err_msg] } {
    incr exception_count
    append exception_text "  <li> $err_msg\n"
} else {
    ns_set put $form_setid {dp.im_employee_info.birthdate} $birthdate
}

if { [catch {set first_experience [validate_ad_dateentrywidget first_experience first_experience [ns_conn form]]} err_msg] } {
    incr exception_count
    append exception_text "  <li> $err_msg\n"
} else {
    ns_set put $form_setid {dp.im_employee_info.first_experience} $first_experience
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


dp_process -db $db -where_clause "user_id=$user_id"


if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect payroll.tcl?[export_url_vars user_id]
}