# File: /www/intranet/hours/week.tcl

ad_page_contract {
    Shows the hour a specified user spend working over the course of a week

    @param on_which_table table we're viewing hours against
    @param julian_date day in julian format in the week we're currently viewing. Defaults to sysdate
    @user_id the user for whom we're viewing hours. Defaults to currently logged in user.
 
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date January 2000
    @cvs-id week.tcl,v 3.7.2.7 2000/09/22 01:38:38 kevin Exp
   
} {
    on_which_table
    { julian_date "" }
    { user_id:integer "" }
}

if { [empty_string_p $user_id] } {
    set user_id [ad_get_user_id]
}


if { [empty_string_p $julian_date] } {
    set julian_date [db_string sysdate_as_julian \
	    "select to_char(sysdate,'J') from dual"]
}

set user_name [db_string user_name \
	"select first_names || ' ' || last_name from users where user_id = :user_id"]

db_1row week_select_start_and_end \
	"select to_char( next_day(
    	    	   to_date( :julian_date, 'J' )-1, 'sat' ),
    	    	  'MM/DD/YYYY' ) AS end_date,
	        to_char( next_day(
    	    	    to_date( :julian_date, 'J' )-1, 'sat' )-6,
    	    	  'MM/DD/YYYY' ) AS start_date
    	 from dual"

set sql "SELECT g.group_id, g.group_name, sum(h.hours) as total
    	 FROM im_hours h, user_groups g
    	 WHERE g.group_id = h.on_what_id
    	   AND h.on_which_table = :on_which_table
    	   AND h.day >= trunc( to_date( :start_date, 'MM/DD/YYYY' ) )
    	   AND h.day < trunc( to_date( :end_date, 'MM/DD/YYYY' ) ) + 1
    	   AND h.user_id=:user_id
    	 GROUP BY g.group_id, g.group_name"

set items {}
set grand_total 0

db_foreach hour_select $sql {
    set grand_total [expr $grand_total+$total]
    lappend items [list $group_id $group_name $total]
}

set sql "SELECT g.group_id, g.group_name, nvl(h.note,'<i>none</i>') as note,
		TO_CHAR( day, 'Dy, MM/DD/YYYY' ) as nice_day
	 FROM im_hours h, user_groups g
	 WHERE g.group_id = h.on_what_id
     	   AND h.on_which_table = :on_which_table
    	   AND h.day >= trunc( to_date( :start_date, 'MM/DD/YYYY' ) )
    	   AND h.day < trunc( to_date( :end_date, 'MM/DD/YYYY' ) ) + 1
    	   AND user_id=:user_id
	 ORDER BY lower(g.group_name), day"

set last_id -1
set pcount 0
set notes "<hr>\n<h2>Daily project notes</h2>\n"

db_foreach hours_daily_project_notes $sql {
    if { $last_id != $group_id } {
	set last_id $group_id
	if { $pcount > 0 } {
	    append notes "</ul>\n"
	}
	append notes "<h3>$group_name</h3>\n<ul>\n"
	incr pcount
    }
    append notes "<li><b>$nice_day:</b>&nbsp;$note\n"
}

if { $pcount > 0 } {
    append notes "</ul>\n"
} else {
    set notes ""
}

db_release_unused_handles

set hour_table "No hours for this week"

if {[llength $items] > 0 } {
    set hour_table "<table cellspacing=1 cellpadding=3>
    <tr bgcolor=\"#666666\">
    <th><font color=\"#ffffff\">Project</font></th>
    <th><font color=\"#ffffff\">Hours</font></th>
    <th><font color=\"#ffffff\">Percentage</font></th>
    </tr>
    "

    foreach row $items {
	set group_id [lindex $row 0]
	set group_name [lindex $row 1]
	set total [lindex $row 2]
	append hour_table "<tr bgcolor=\"#efefef\">
	<td><a href=\"../projects/view?[export_url_vars group_id]\">
	    $group_name</a></td>
	<td align=right>[format "%0.02f" $total]</td>
	<td align=right>[format "%0.02f%%" \
	    [expr double($total)/$grand_total*100]]</td>
	</tr>
	"
    }

    append hour_table "<tr bgcolor=\"#aaaaaa\">
    	<td><b>Grand Total</b></td>
    	<td align=right><b>[format "%0.02f" $grand_total]</b></td>
    	<td align=right><b>100.00%</b></td>
    	</tr>
    	</table>\n"
}

set page_title "Weekly total by $user_name"
set context_bar [ad_context_bar_ws [list index?[export_url_vars on_which_table] "Your hours"] "Weekly hours"]

set page_body "
$hour_table
$notes
"

doc_return  200 text/html [im_return_template]

