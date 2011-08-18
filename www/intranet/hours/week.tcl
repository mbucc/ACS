# $Id: week.tcl,v 3.1.4.1 2000/03/17 08:22:58 mbryzek Exp $
# File: /www/intranet/hours/week.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Shows the hour a specified user spend working over the course of a week
# 

set_the_usual_form_variables
# expect: julian_date
# on_which_table
# optional: user_id

if { ![info exists user_id] } {
    set user_id [ad_get_user_id]
}

set db [ns_db gethandle]

set user_name [database_to_tcl_string $db \
	"select first_names || ' ' || last_name from users where user_id = $user_id"]

set selection [ns_db 1row $db \
	"select to_char( next_day(
    	    	    to_date( $julian_date, 'J' )-1, 'sat' ),
    	    	  'MM/DD/YYYY' ) AS end_date,
	        to_char( next_day(
    	    	    to_date( $julian_date, 'J' )-1, 'sat' )-6,
    	    	  'MM/DD/YYYY' ) AS start_date
    	 from dual"]

set_variables_after_query



set selection [ns_db select $db \
	"SELECT g.group_id, g.group_name, sum(h.hours) as total
    	 FROM im_hours h, user_groups g
    	 WHERE g.group_id = h.on_what_id
    	   AND h.on_which_table = '$QQon_which_table'
    	   AND h.day >= trunc( to_date( '$start_date', 'MM/DD/YYYY' ) )
    	   AND h.day < trunc( to_date( '$end_date', 'MM/DD/YYYY' ) ) + 1
    	   AND h.user_id=$user_id
    	 GROUP BY g.group_id, g.group_name"]

set items {}
set grand_total 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set grand_total [expr $grand_total+$total]
    lappend items [ns_set copy $selection]
}

set selection [ns_db select $db \
	"SELECT g.group_id, g.group_name, nvl(h.note,'<i>none</i>') as note,
		TO_CHAR( day, 'Dy, MM/DD/YYYY' ) as nice_day
	 FROM im_hours h, user_groups g
	 WHERE g.group_id = h.on_what_id
     	   AND h.on_which_table = '$QQon_which_table'
    	   AND h.day >= trunc( to_date( '$start_date', 'MM/DD/YYYY' ) )
    	   AND h.day < trunc( to_date( '$end_date', 'MM/DD/YYYY' ) ) + 1
    	   AND user_id=$user_id
	 ORDER BY lower(g.group_name), day"]

set last_id -1
set pcount 0
set notes "<hr>\n<h2>Daily project notes</h2>\n"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
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

ns_db releasehandle $db

set hour_table "No hours for this week"

if {[llength $items] > 0 } {
    set hour_table "<table cellspacing=1 cellpadding=3>
    <tr bgcolor=\"#666666\">
    <th><font color=\"#ffffff\">Project</font></th>
    <th><font color=\"#ffffff\">Hours</font></th>
    <th><font color=\"#ffffff\">Percentage</font></th>
    </tr>
    "

    foreach selection $items {
	set_variables_after_query
	append hour_table "<tr bgcolor=\"#efefef\">
	<td><a href=\"../projects/view.tcl?[export_url_vars group_id on_which_table]\">
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
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" Intranet] [list index.tcl?[export_url_vars on_which_table] "Your hours"] "Weekly hours"]

set page_body "
$hour_table
$notes
"

ns_return 200 text/html [ad_partner_return_template]
