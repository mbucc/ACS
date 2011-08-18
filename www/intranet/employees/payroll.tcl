# $Id: payroll.tcl,v 3.2.2.3 2000/04/28 15:11:06 carsten Exp $
#
# File: /www/intranet/employees/payroll.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Shows payroll information about one employee
#
# Mar 15 2000 mbryzek: Removed ns_writes

ad_maybe_redirect_for_registration

set_form_variables 0
# user_id 
# return_url (optional)


if { ![exists_and_not_null user_id] } {
    set user_id [ad_verify_and_get_user_id]
}

set caller_user_id $user_id 

set db [ns_db gethandle]

# This page is restricted to only site/intranet admins
if { $caller_user_id != [ad_verify_and_get_user_id] && ![im_is_user_site_wide_or_intranet_admin $db] } {
    ad_returnredirect ../
    return
}

set default_value "<em>(No information)</em>"

set selection [ns_db 0or1row $db "
select 
  u.first_names, 
  u.last_name, 
  u.email, 
  (sysdate - info.first_experience)/365 as total_years_experience,
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
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl "Employees"] [list ../users/view.tcl?user_id=$caller_user_id "One employee"] "Payroll information"]

ns_db releasehandle $db

if [empty_string_p $salary] {
    set salary "<em>(No information)</em>"
} else {
    set salary [im_display_salary $salary $salary_period]
}
if [empty_string_p $total_years_experience] {
    set total_years_experience "<em>(No information)</em>"
} else {
    set total_years_experience "[format %4.1f $total_years_experience] [util_decode $total_years_experience 1 year years]"
}
if [empty_string_p $ss_number] {
    set ss_number "(No information)"
}
if [empty_string_p $dependants] {
    set dependants "(No information)"
}
if [empty_string_p $birthdate] {
    set birthdate "<EM>(No information)</EM>"
} else {
    set birthdate "[util_AnsiDatetoPrettyDate $birthdate]"
}


set page_body "
<b>Salary:</b> $salary
<br><b>Years of relevant work experience:</b> $total_years_experience
<p><b>W-2 information:</b>
<ul>

<BLOCKQUOTE>

<TABLE CELLPADDING=3>

<TR>
<TD>Social Security number:</TD>
<TD><EM>$ss_number</EM></TD>
</TR>

<TR>
<TD>Birthdate:</TD>
<TD><EM>$birthdate</EM></TD>
</TR>

<TR>
<TD>Are you married?</TD>
<TD><EM>[util_PrettyBoolean $married_p $default_value]</EM></TD>
</TR>

<TR>
<TD>Are you a dependant? <br><font size=-1>(Does someone else claim you on their tax return?)</font></TD>
<TD><EM>[util_PrettyBoolean $dependant_p $default_value]</EM></TD>
</TR>

<TR>
<TD>Is this your only job?</TD>
<TD><EM>[util_PrettyBoolean $only_job_p $default_value]</EM></TD>
</TR>

<TR>
<TD>Are you the head of the household?</TD>
<TD><EM>[util_PrettyBoolean $head_of_household_p $default_value]</EM></TD>
</TR>

<TR>
<TD>Number of dependants:</TD>
<TD><EM>$dependants</EM></TD>
</TR>

</TABLE>
</blockquote>

</ul>

(<a href=payroll-edit.tcl?user_id=$caller_user_id&[export_url_vars return_url]>edit</a>)
"

ns_return 200 text/html [ad_partner_return_template]
