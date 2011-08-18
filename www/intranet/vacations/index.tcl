# $Id: index.tcl,v 3.0.4.1 2000/03/17 08:23:27 mbryzek Exp $
# File: /www/intranet/vacations/index.tcl
#
# Mar 16 2000: mbryzek@arsdigita.com: removed ns_writes
#
# Dec 29 1999: ahmedaa@mit.edu, 
#  made it viewable by normal people
# 
# Purpose: shows all office absences
#

#expected variables: vacation_type and/or period or none
set_the_usual_form_variables 0

if ![info exists period] {
    set period ""
}

if { ![info exists vacation_type] || $vacation_type == "all" } {
    set extra_sql ""
    set vacation_type "all"
    set slider "<table width=100%><tr><td align=left>\[all\]"
} else {
    set extra_sql "and vacation_type = '[string tolower $vacation_type]'"
    set slider "<table width=100%><tr><td align=left>\[<a href=index.tcl?period=$period>all</a>\]"
}

set absence_types [ad_parameter AbsenceTypes pvt "travel sick vacation personal"]

foreach ab_type $absence_types {
    if { $ab_type == $vacation_type } {
	append slider "\[$ab_type\]"
    } else {
	append slider "\[<a href=index.tcl?vacation_type=$ab_type&period=$period>$ab_type</a>\]"
    }
}

if { [empty_string_p $period]} {
    set extra_period_sql "and end_date > sysdate"
    set period ""
    append slider "<td align=right>\[<a href=index.tcl?period=current&vacation_type=$vacation_type>current</a>\]\[<a href=index.tcl?period=future&vacation_type=$vacation_type>future</a>\]\[<a href=index.tcl?period=past&vacation_type=$vacation_type>past</a>\]</table>"
}  elseif { $period == "current" } {
    set extra_period_sql "and end_date >= sysdate and start_date <= sysdate"
    append slider "<td align=right>\[current\]\[<a href=index.tcl?period=future&vacation_type=$vacation_type>future</a>\]\[<a href=index.tcl?period=past&vacation_type=$vacation_type>past</a>\]</table>"
} elseif { $period == "past" } {
    set extra_period_sql "and end_date < sysdate"
    append slider "<td align=right>\[<a href=index.tcl?period=current&vacation_type=$vacation_type>current</a>\]\[<a href=index.tcl?period=future&vacation_type=$vacation_type>future</a>\]\[past\]</table>"
} else {
    # future
    set extra_period_sql "and start_date > sysdate"
    append slider "<td align=right>\[<a href=index.tcl?period=current&vacation_type=$vacation_type>current</a>\]\[future\]\[<a href=index.tcl?period=past&vacation_type=$vacation_type>past</a>\]</table>"
}

set page_body "
[ad_header "Vacations" ]
<h2>Work Absences: $vacation_type</h2>


[ad_context_bar [list "../index.tcl" "Intranet"] "Work Absences ($vacation_type)"]
<hr>
$slider

<blockquote>
<table width=80%>"

set db [ns_db gethandle]
set sql_query  "select start_date, end_date, users.user_id, 
users.first_names || ' ' || users.last_name as name, vacation_id, end_date-start_date as duration
from user_vacations, users
where user_vacations.user_id =users.user_id
$extra_sql
$extra_period_sql
order by start_date asc"

set selection [ns_db select $db $sql_query] 
set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
    append page_body "<tr><td align=left><a href=one-user.tcl?[export_url_vars user_id]>$name</a> <td align=left>[nmc_IllustraDatetoPrettyDate $start_date] - [nmc_IllustraDatetoPrettyDate $end_date] <td align=left> $duration days <td align=left><a href=edit.tcl?[export_url_vars vacation_id]>edit</a>"
}

append page_body "</table></blockquote>"

if { $counter == 0 } {
    append page_body "There are no office absences of type \" $period [string tolower $vacation_type]\" in the database right now.<p>"
}

append page_body "<p><a href=\"add.tcl\">Add an office absence</a><p>
[ad_footer]"

ns_db releasehandle $db

ns_return 200 text/html $page_body

