# /www/intranet/employees/report.tcl

ad_page_contract {
    Purpose: A status report of an employee (similar to 
company status report) that includes:
* Work Log
* Previous week's time allocation (compared to estimate)
* Estimate of following week's time allocation
* Posted Status Reports for projects

    @param user_id 
    @param coverage_days 

    @author mbryzek@arsdigita.com
    @creation-date 4/6/2000

    @cvs-id report.tcl,v 3.7.2.7 2000/09/22 01:38:31 kevin Exp
} {
    { user_id:integer "" }
    { coverage_days 7 }
}

set html_p t

if { [empty_string_p $user_id] } {
    set user_id [ad_maybe_redirect_for_registration]
}

set user_name [db_string display_name  \
	"select first_names || ' ' || last_name from users where user_id= :user_id"]

db_release_unused_handles

# Any late project reports?
set late_project_reports [im_late_project_reports $db $user_id $html_p $coverage_days]
if { [empty_string_p $late_project_reports] } {
    set late_project_reports "<li><i>none</i>\n"
}
set late_project_reports "<ul>$late_project_reports</ul>"

# Any submitted project reports?
set project_reports [im_project_reports $coverage_days "" web_display $user_id]

# How many hours have been logged and for what?
set hours [im_hours_for_user $user_id $html_p $coverage_days]

set page_title "Status Report for $user_name"
set context_bar [ad_context_bar_ws [list ./ "Employees"] [list ../users/view?[export_url_vars user_id] "One employee"] "Status report"]

set report_date [db_string get_date "select sysdate from dual"] 
set n_days_possible [list 1 2 3 4 5 6 7 14 30]

set coverage_menu ""

foreach n_days $n_days_possible {
    append coverage_menu [util_decode $n_days $coverage_days $n_days "<a href=report?coverage_days=$n_days>$n_days</a>"]
    append coverage_menu " "
}

set page_body "
<table width=100%>
<tr>
  <td align=left>Report date: [util_AnsiDatetoPrettyDate $report_date]</td>
  <td align=right>Coverage: $coverage_menu days</a>
</tr>
</table>

<h3>Hours</h3>
$hours

<h3>Late project reports</h3>
$late_project_reports

<h3>Project reports</h3>
$project_reports

"

doc_return  200 text/html [im_return_template]
