# $Id: status-report.tcl,v 3.3.4.2 2000/03/17 08:56:31 mbryzek Exp $
#
# File: /www/intranet/status-report.tcl
#
# by teadams@mit.edu on Dec 10, 1999
# last modified: sunday december 26 by ahmedaa@mit.edu

# gives the random user a comprehensive view of 
# the company's status 

set_the_usual_form_variables 0

set db [ns_db gethandle]
ad_maybe_redirect_for_registration

if { ![im_user_is_employee_p $db [ad_verify_and_get_user_id]] } {
    ad_return_error "Access denied" "You must be an employee to see this page"
    return
}

# coverage_days 

if ![info exists coverage_days] {
    set coverage_days 1
}

set page_title "Intranet Status Report"
set context_bar [ad_context_bar [list index.tcl "Intranet"] "Status report"]

set report_date [database_to_tcl_string $db "select sysdate from dual"] 

set n_days_possible [list 1 2 3 4 5 6 7 14 30]

set right_widget [list]

foreach n_days $n_days_possible {
    if { $n_days == $coverage_days } {
	# current choice, just the item
	lappend right_widget_items $n_days
    } else {
	lappend right_widget_items "<a href=\"status-report.tcl?coverage_days=$n_days\">$n_days</a>"
    }
}



set right_widget [join $right_widget_items]

set page_body "
<table width=100%>
<tr>
  <td align=left>Report date: [util_IllustraDatetoPrettyDate $report_date]</td>
  <td align=right>Coverage: $right_widget days</a>
</tr>
</table>

<p>

"

append page_body [im_status_report $db $coverage_days $report_date "web_display" "im_status_report_section_list"]

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]

 