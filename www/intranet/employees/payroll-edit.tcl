# $Id: payroll-edit.tcl,v 3.2.2.3 2000/04/28 15:11:06 carsten Exp $
#
# File: /www/intranet/employees/payroll-edit.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Allows users to enter payroll info
#

ad_maybe_redirect_for_registration

set_form_variables 0
# user_id 
# return_url (optional)

set caller_user_id $user_id 

if { ![exists_and_not_null user_id] } {
    ad_return_error "Missing user id" "We weren't able to determine  forwhat user you want information."
    return
}

set db [ns_db gethandle]

# This page is restricted to only site/intranet admins or the person
# whose record this is
if { $caller_user_id != [ad_verify_and_get_user_id] && ![im_is_user_site_wide_or_intranet_admin $db] } {
    ad_returnredirect ../
    return
}

set selection [ns_db 0or1row $db "
select 
  u.first_names, 
  u.last_name, 
  u.email, 
  (sysdate - info.first_experience)/365 as years_experience,
  info.*
from users u, im_employee_info info
where u.user_id = $user_id
and u.user_id = info.user_id(+)
and ad_group_member_p ( u.user_id, [im_employee_group_id] ) = 't'"]

if [empty_string_p $selection] {
    ad_return_error "Error" "That user doesn't exist"
    return
}
set_variables_after_query

set page_title "$first_names $last_name"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl "Employees"] [list ../users/view.tcl?user_id=$caller_user_id "One employee"] [list payroll.tcl?user_id=$caller_user_id "Payroll information"] "Edit information"]

set user_admin_p [im_is_user_site_wide_or_intranet_admin $db $user_id]
if { $user_admin_p } {
    set salary_info "
<tr>
 <td>Salary (per year)</td>
 <td><input NAME=dp.im_employee_info.salary.money MAXLENGTH=20 [export_form_value salary]></td>
</tr>
"
} else {
    set salary_info ""
}

ns_db releasehandle $db


set page_body "
<form method=post action=payroll-edit-2.tcl>
<input type=hidden name=dp.im_employee_info.user_id value=$user_id>
[export_form_vars return_url]
<table>
$salary_info
<tr>
 <td>Social Security Number</td>
 <td><input NAME=dp.im_employee_info.ss_number MAXLENGTH=20 [export_form_value ss_number]></td>
</tr>

<tr>
 <td>Birthdate:</td>
 <td>[ad_dateentrywidget birthdate [value_if_exists birthdate]]</td>
</tr>

<tr>
 <td>Are you married?</td>
 <td><SELECT NAME=dp.im_employee_info.married_p>
 [ad_generic_optionlist [list No Yes] [list f t] [value_if_exists married_p]]
 </SELECT>
 </td>
</tr>

<tr>
 <td>Are you a dependent?<br>(Does someone else claim you on your
 tax return?)</td>
 <td>
 <SELECT NAME=dp.im_employee_info.dependant_p>
 [ad_generic_optionlist [list No Yes] [list f t] [value_if_exists dependant_p]]
 </SELECT>
 </td>
</tr>

<tr>
 <td>Is this your only job?</td>
 <td><SELECT NAME=dp.im_employee_info.only_job_p>
 [ad_generic_optionlist [list Yes No] [list t f] [value_if_exists only_job_p]]
 </SELECT>
 </td>
</tr>

<tr>
 <td>Are you the head of the household?</td>
 <td><SELECT NAME=dp.im_employee_info.head_of_household_p>
 [ad_generic_optionlist [list Yes No] [list t f] [value_if_exists head_of_household_p]]
 </SELECT>
 </td>
</tr>

<tr>
 <td>Number of dependents:</td>
 <td><input NAME=dp.im_employee_info.dependants [export_form_value dependants] SIZE=2 MAXLENGTH=2></td>
</tr>

<tr>
 <td colspan=2>&nbsp;</td>
</tr>

<tr>
 <td><B>Experience.</B> When did you start work in this field?</td>
 <td>[ad_dateentrywidget first_experience [value_if_exists first_experience]]</td>
</tr>

</table>

<p><CENTER>
<input TYPE=Submit VALUE=\" Update \">
</center>

</form>
"

ns_return 200 text/html [ad_partner_return_template]