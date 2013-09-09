# /www/intranet/employees/payroll.tcl

ad_page_contract {
    Shows payroll information about one employee
Mar 15 2000 mbryzek

    @param user_id     whose payroll we're examining
    @param return_url  where to redirect to 

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id payroll.tcl,v 3.9.2.9 2000/09/22 01:38:31 kevin Exp
} {
    {user_id:integer [ad_maybe_redirect_for_registration] }
    return_url:optional
}

#set caller_user_id [ad_maybe_redirect_for_registration]

set caller_user_id $user_id 



# This page is restricted to only site/intranet admins
if { $caller_user_id != [ad_verify_and_get_user_id] && ![im_is_user_site_wide_or_intranet_admin] } {
    ad_returnredirect ../
    return
}

set default_value "<em>(No information)</em>"

set employee_details_sql "select 
  u.first_names, 
  u.last_name, 
  u.email, 
  (sysdate - info.first_experience)/365 as total_years_experience,
  info.*
from users u, im_employee_info info
where u.user_id = :user_id
and u.user_id = info.user_id(+)
and ad_group_member_p ( u.user_id, [im_employee_group_id] ) = 't'"

if {[db_0or1row employee_details $employee_details_sql] == 0} {
    ad_return_error "Error" "That user doesn't exist"
    return
}  


set page_title "$first_names $last_name"
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list ../users/view?user_id=$caller_user_id "One employee"] "Payroll information"]

db_release_unused_handles

if [empty_string_p $salary] {
    set salary "<em>(No information)</em>"
} else {
    set salary [im_display_salary $salary [im_salary_period_input]]
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

(<a href=payroll-edit?user_id=$user_id&[export_url_vars return_url]>edit</a>)
"

doc_return  200 text/html [im_return_template]


