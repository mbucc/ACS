# /www/intranet/absences/index.tcl
ad_page_contract {
    Shows table of Employee, Absence type, Date of absence, duration
    of absence. Made it viewable by normal people.

    @param period time looking at, one of: current "next month" future past
    @param vacation_type one of: all travel sick vacation personal
    @param mine_p "f" - if Everyone.  "t" - if Mine. 
    @param orderby - for ad_table_display
 
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @author (ahmedaa@mit)
    @cvs-id index.tcl,v 1.5.2.7 2000/09/22 01:38:25 kevin Exp   
} {
    { period "current" }
    { vacation_type "all" }
    { mine_p "f" }
    { orderby "start_date" } 
}

set criteria [list]

# Generate slider for vacation type
set types_list [list "all" "all"]
foreach cat [ad_parameter AbsenceTypes pvt "travel sick vacation personal"] {
    lappend types_list $cat $cat
}

if { [string compare [string tolower $vacation_type] "all"] != 0 } {
    lappend criteria "uv.vacation_type = '[string tolower $vacation_type]'"
}

# generate slider options my vacations vs all vacations
set mine_list [list "t" "Mine" "f" "Everyone"]
switch $mine_p {
    "t" { lappend criteria "users.user_id = '[ad_get_user_id]'" }
}

# generate slider options for period
set period_list [list]
foreach cat [list all current "next month" future past] {
    lappend period_list $cat $cat
}


# We knowingly use trunc on start and end dates for the "current" period
# because we know that any date index will be ignored in favor of other
# indexes in the query. The trunc is necessary to ensure the current 
# period includes 1-day absences for today.
switch $period {
    "current" { lappend criteria "trunc(uv.start_date) <= trunc(sysdate) and trunc(uv.end_date) >= trunc(sysdate)" }
    "future" { lappend criteria "uv.start_date > trunc(sysdate)" }
    "next month" { lappend criteria "uv.start_date > trunc(sysdate) and uv.start_date <= add_months(trunc(sysdate),1)" }
    "past" { lappend criteria "uv.end_date < trunc(sysdate)" }
}

if { [llength $criteria] > 0 } {
    set where_clause " and [join $criteria "\n       and "]"
} else {
    set where_clause ""
}

set page_body "
<blockquote>

<table width=80% border=0 cellspacing=2 cellpadding=0>
 <tr bgcolor=eeeeee>
  <th>Type</th>
  <th>Whose</th>
  <th>When</th>
 </tr>
 <tr>
  <td align=center valign=top>[im_slider vacation_type $types_list]</td>
  <td align=center valign=top>[im_slider mine_p $mine_list]</td>
  <td align=center valign=top>[im_slider period $period_list]</td>
 </tr>
</table>
<p>
"

set table_def { 
    {name "Employee" \
	    {name $order} \
	    {<td align=left><a href=one-user?[export_url_vars user_id]>$name</a></td>}}
    {vacation_type "Absence type" \
	    {vacation_type $order} \
	    {<td align=left>$vacation_type</td>}}
    {start_date "Date" \
	    {start_date $order} \
	    {<td align=left><a href=edit?[export_url_vars vacation_id]>[util_AnsiDatetoPrettyDate $start_date] - [util_AnsiDatetoPrettyDate $end_date]</a></td>}}
    {duration "Duration" \
	    {duration $order} \
	    {<td align=left> [util_commify_number [format "%.0f" $duration]] [util_decode $duration "1" day days]</td>}}
}


set sql	"select uv.start_date, uv.end_date, users.user_id, nvl(uv.vacation_type,'unknown') as vacation_type,
                users.first_names || ' ' || users.last_name as name, 
                uv.vacation_id, 1+uv.end_date-uv.start_date as duration
           from user_vacations uv, im_employees_active users
          where uv.user_id = users.user_id $where_clause [ad_order_by_from_sort_spec $orderby $table_def]"

set missing_text "There are currently no office absences matching the selected criteria."

append page_body "
[ad_table -Torderby $orderby -Ttable_extra_html "width=80%" -Tmissing_text $missing_text show_table $sql $table_def]
<p><a href=\"add\">Add an office absence</a><p>
</blockquote>
"

db_release_unused_handles

set page_title "Work Absences ($vacation_type)"
set context_bar [ad_context_bar_ws "Work Absences"]

doc_return  200 text/html [im_return_template]

