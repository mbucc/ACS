# /www/intranet/employees/payroll-edit.tcl



ad_page_contract {
    Allows users to enter payroll info

    @param user_id user we're examining
    @param return_url where to redirect to on completion

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id payroll-edit.tcl,v 3.9.2.7 2000/09/22 01:38:31 kevin Exp
} {
    user_id:integer,optional
    return_url:optional
}


set caller_user_id [ad_maybe_redirect_for_registration]

if { ![exists_and_not_null user_id] } {
    ad_return_error "Missing user id" "We weren't able to determine  forwhat user you want information."
    return
}



# This page is restricted to only site/intranet admins or the person
# whose record this is
if { $caller_user_id != [ad_verify_and_get_user_id] && ![im_is_user_site_wide_or_intranet_admin] } {
    ad_returnredirect index
    return 
}



set payroll_details_sql "
select 
  u.first_names, 
  u.last_name, 
  u.email, 
  (sysdate - info.first_experience)/365 as years_experience,
  info.*
from users u, im_employee_info info
where u.user_id = :user_id
and u.user_id = info.user_id(+)
and ad_group_member_p ( u.user_id, [im_employee_group_id] ) = 't'"


if {[db_0or1row payroll_details $payroll_details_sql] == 0} {
    ad_return_error "Error" "That user doesn't exist"
    return
}


set page_title "$first_names $last_name"
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list ../users/view?user_id=$caller_user_id "One employee"] [list payroll?user_id=$caller_user_id "Payroll information"] "Edit information"]

set user_admin_p [im_is_user_site_wide_or_intranet_admin $caller_user_id]
if { $user_admin_p } {
    set salary_info "
<tr>
 <td>Salary (per [ad_parameter SalaryPeriodInput intranet])</td>
 <td><input NAME=dp.im_employee_info.salary.money MAXLENGTH=20 value=\"[util_commify_number [value_if_exists salary]]\"></td>
</tr>
"
} else {
    set salary_info ""
}

db_release_unused_handles

set page_body "
<form method=post action=payroll-edit-2>
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

doc_return  200 text/html [im_return_template]
