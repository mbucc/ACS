# $Id: info-update.tcl,v 3.5.2.2 2000/03/17 07:26:06 mbryzek Exp $
#
# File: /www/intranet/employees/admin/info-update.tcl
# Author: mbryzek@arsdigita.com, Jan 2000
# Allows admin to update an employees info

ad_maybe_redirect_for_registration

set_form_variables 0
# user_id 
# return_url (optional)

if { ![exists_and_not_null user_id] } {
    ad_return_error "Missing user id" "We weren't able to determine what user you want information for."
    return
}

set calling_user_id $user_id

set db [ns_db gethandle]

set percentages [list 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0]


set selection [ns_db 0or1row $db \
	"select users.*, info.*
           from users, im_employee_info info
          where users.user_id = info.user_id(+)
            and users.user_id = $calling_user_id"]

if [empty_string_p $selection] {
    ad_return_error "Error" "That user doesn't exist"
    return
} 
set_variables_after_query

set office_id [database_to_tcl_string_or_null $db \
	"select group_id
           from im_offices
          where ad_group_member_p ( $calling_user_id, group_id ) = 't'"]

set office_sql \
	"select g.group_name, g.group_id
           from user_groups g, im_offices o
          where o.group_id=g.group_id
       order by lower(g.group_name)"

set offices_html "
<select name=office_id>
<option value=\"\"> -- Please select --
[ad_db_optionlist $db $office_sql [value_if_exists office_id]]
</select>
"


set salary_period_input [im_salary_period_input]
if { [empty_string_p $salary_period_input] } {
    set salary_period_input month
}


if { ![exists_and_not_null start_date] } {
    set start_date [database_to_tcl_string $db "select sysdate from dual"]
}

if { ![info exists most_recent_review] || [empty_string_p $most_recent_review] } {
    set most_recent_review_html "
    <tr>
    <th align=right valign=top>Most recent review</th>
    <td>
    [ad_dateentrywidget most_recent_review [value_if_exists most_recent_review]]
    </td>
    </tr>"

} else {
    set most_recent_review_html "
    <tr>
    <th align=right valign=top>Most recent review</th>
    <td>
    [ad_dateentrywidget most_recent_review [value_if_exists most_recent_review]]
    </td>
    </tr>
    "

}

set page_title "Edit \"$first_names $last_name\""
set context_bar [ad_context_bar [list "/" Home] [list ../../index.tcl "Intranet"] [list index.tcl "Employees"] [list view.tcl?[export_url_vars user_id] "One employee"] "Edit employee"]

ReturnHeadersNoCache 
ns_write "
[ad_partner_header]
<form method=post action=info-update-2.tcl>
[export_form_vars return_url]
<input type=hidden name=dp.im_employee_info.user_id value=$calling_user_id>

<table cellpadding=3>

<tr>
  <th align=right>Salary (per $salary_period_input):</th>
  <td>\$<input name=dp.im_employee_info.salary.money size=10 [export_form_value salary]></TD>
</tr>

<tr>
  <th align=right>Office:</th>
  <td>$offices_html</td>
</tr>

<tr>
  <th align=right>Job title:</th>
  <td><input name=dp.im_employee_info.job_title size=30 [export_form_value job_title]></td>
</tr>

<tr>
  <th align=right>Start date:</th>
  <td>[ad_dateentrywidget start_date [value_if_exists start_date]]</td>
</tr>

<tr>
 <th align=right>Manages group:</th><td><input name=dp.im_employee_info.group_manages size=30 [export_form_value group_manages]>
</tr>

<tr>
 <th align=right>Team leader?</th>
<td><input type=radio name=dp.im_employee_info.team_leader_p value=t[util_decode [value_if_exists team_leader_p] t " checked" ""]> Yes
    <input type=radio name=dp.im_employee_info.team_leader_p value=f[util_decode [value_if_exists team_leader_p] t "" " checked"]>No
</td>
</tr>

<tr>
 <th align=right>Project lead?</th>
<td><input type=radio name=dp.im_employee_info.project_lead_p value=t[util_decode [value_if_exists project_lead_p] t " checked" ""]> Yes
<input type=radio name=dp.im_employee_info.project_lead_p value=f[util_decode [value_if_exists project_lead_p] t "" " checked"]>No
</tr>

<tr>
 <th align=right>Select Referred By?</th>
<td><input type=radio name=select_referred_by value=t> Yes
    <input type=radio name=select_referred_by value=f checked> No
</td>
</tr>

<tr>
 <TH align=right valign=top>Job Description:</th>
 <TD>
 <TEXTAREA name=dp.im_employee_info.job_description COLS=40 ROWS=6 WRAP=SOFT>[philg_quote_double_quotes $job_description]</TEXTAREA>
 </TD>
</TR>

<tr>
<th align=right valign=top>Received offer letter?</th>
<td>
<input type=radio name=dp.im_employee_info.received_offer_letter_p value=t[util_decode [value_if_exists received_offer_letter_p] t " checked" ""]> Yes
<input type=radio name=dp.im_employee_info.received_offer_letter_p value=f[util_decode [value_if_exists received_offer_letter_p] t "" " checked"]>No
</td>
</tr>

<tr>
<th align=right valign=top>Returned offer letter?</th>
<td>
<input type=radio name=dp.im_employee_info.returned_offer_letter_p value=t[util_decode [value_if_exists returned_offer_letter_p] t " checked" ""]> Yes
<input type=radio name=dp.im_employee_info.returned_offer_letter_p value=f[util_decode [value_if_exists returned_offer_letter_p] t "" " checked"]>No
</td>
</tr>

<tr>
<th align=right valign=top>Signed cc agreement?</th>
<td>
<input type=radio name=dp.im_employee_info.signed_confidentiality_p value=t[util_decode [value_if_exists signed_confidentiality_p] t " checked" ""]> Yes
<input type=radio name=dp.im_employee_info.signed_confidentiality_p value=f[util_decode [value_if_exists signed_confidentiality_p] t "" " checked"]>No
</td>
</tr>

$most_recent_review_html

<tr>
<th align=right valign=top>Most recent review in folder?</th>
<td>
<input type=radio name=dp.im_employee_info.most_recent_review_in_folder_p value=t[util_decode [value_if_exists most_recent_review_in_folder_p] t " checked" ""]> Yes
<input type=radio name=dp.im_employee_info.most_recent_review_in_folder_p value=f[util_decode [value_if_exists most_recent_review_in_folder_p] t "" " checked"]>No
</td>
</tr>

<tr>
 <TH align=right valign=top>Biography:</th>
 <TD>
 <textarea name=dp.users.bio cols=40 rows=6 wrap=soft>[philg_quote_double_quotes $bio]</TEXTAREA>
 </TD>
</TR>

<tr>
 <TH align=right valign=top>Featured Employee Blurb:</th>
 <TD>
 <textarea name=dp.im_employee_info.featured_employee_blurb cols=40 rows=6 wrap=soft>[philg_quote_double_quotes $featured_employee_blurb]</TEXTAREA>
 </TD>
</TR>


<tr>
<th align=right valign=top>Blurb Approved?</th>
<td>
<input type=radio name=dp.im_employee_info.featured_employee_approved_p value=t[util_decode [value_if_exists featured_employee_approved_p] t " checked" ""]> Yes
<input type=radio name=dp.im_employee_info.featured_employee_approved_p value=f[util_decode [value_if_exists featured_employee_approved_p] t "" " checked"]>No
</td>
</tr>


</table>

<P><center>
<input type=submit value=Update>
</center>
</form>

[ad_footer]
"
