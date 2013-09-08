# /www/intranet/employees/admin/employment-info-update.tcl

ad_page_contract {
    Allows admin to update an employees info
    
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id employment-info-update.tcl,v 3.4.2.7 2000/09/22 01:38:33 kevin Exp
    @param user_id The user whose info we are updating
    @param return_url The url to bounce back to
} {
    user_id:integer
    {return_url ""}
}

ad_maybe_redirect_for_registration


set calling_user_id $user_id



set percentages [list 100 95 90 85 80 75 70 65 60 55 50 45 40 35 30 25 20 15 10 5 0]

db_0or1row get_user_info_for_update \
	"select u.first_names, u.last_name, u.email, 
                info.most_recent_review, info.salary, info.referred_by, info.start_date,
                info.most_recent_review_in_folder_p, info.job_description
           from users u, im_employee_info info
          where u.user_id = info.user_id(+)
            and u.user_id = :calling_user_id"

if ![info exists first_names] {
    ad_return_error "Error" "That user doesn't exist"
    return
} 

set salary_period_input [im_salary_period_input]
if { [empty_string_p $salary_period_input] } {
    set salary_period_input month
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
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list view?[export_url_vars user_id] "One employee"] "Edit employee"]

doc_return  200 text/html "
[im_header]
<form method=post action=employment-info-update-2>
[export_form_vars return_url]
<input type=hidden name=dp.im_employee_info.user_id value=$calling_user_id>

<table cellpadding=3>

<tr>
  <th align=right>Salary (per $salary_period_input):</th>
  <td>\$<input name=dp.im_employee_info.salary.money size=10 value=\"[util_commify_number [value_if_exists salary]]\"></TD>
</tr>

<tr>
  <th align=right>Start date:</th>
  <td>[ad_dateentrywidget start_date [value_if_exists start_date]]</td>
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

$most_recent_review_html

<tr>
<th align=right valign=top>Most recent review in folder?</th>
<td>
<input type=radio name=dp.im_employee_info.most_recent_review_in_folder_p value=t[util_decode [value_if_exists most_recent_review_in_folder_p] t " checked" ""]> Yes
<input type=radio name=dp.im_employee_info.most_recent_review_in_folder_p value=f[util_decode [value_if_exists most_recent_review_in_folder_p] t "" " checked"]>No
</td>
</tr>

</table>

<P><center>
<input type=submit value=Update>
</center>
</form>

[ad_footer]
"
