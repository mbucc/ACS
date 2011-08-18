# $Id: index.tcl,v 3.1.4.1 2000/03/17 08:22:57 mbryzek Exp $
# File: /www/intranet/hours/index.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Calendar format display of user's hours with links 
# to log more hours, if the user is looking at him/
# herself


set_form_variables 0
# on_which_table
# maybe date, maybe user_id, maybe group_id

if { ![exists_and_not_null on_which_table] } {
    set on_which_table im_projects
    set QQon_which_table im_projects
}

set caller_id [ad_get_user_id]

if ![info exists user_id] {
    if {$caller_id} { 
        set user_id $caller_id
    } else {
        ad_maybe_redirect_for_registration
    }
}

if {$user_id == $caller_id} {
    set looking_at_self_p 1
} else {
    set looking_at_self_p 0
}

set db [ns_db gethandle]

set user_name [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $user_id"]

set page_title "Hours by $user_name"
set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] "Hours"]

if [info exists project_id] { 
    set project_name [database_to_tcl_string $db \
	    "select group_name from user_groups where group_id = $group_id"]
    append page_title " on $project_name"
    set project_restriction "and group_id = $group_id"
} else {
    set project_restriction ""
}


# Default to today if there is no date specified
if { ![exists_and_not_null date] } {
    if { [exists_and_not_null julian_date] } {
	set date [database_to_tcl_string $db \
		"select to_char( to_date('$julian_date','J'), 'YYYY-MM-DD') from dual"]
    } else {
	set date [database_to_tcl_string $db \
		"select to_char( sysdate, 'YYYY-MM-DD') from dual"]
    }
} 

set calendar_details [ns_set create calendar_details]

# figure out the first and last julian days in the month
set selection [calendar_get_info_from_db $date]
set_variables_after_query

# Grab all the hours from im_hours
set selection [ns_db select $db \
	"select to_char(day, 'J') as julian_date, sum(hours) as hours
           from im_hours 
          where user_id = $user_id
            and day between to_date($first_julian_date, 'J') 
                            and to_date($last_julian_date, 'J') $project_restriction
       group by to_char(day, 'J')"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set users_hours($julian_date) $hours
}

set hours_for_this_week 0.0
set first_day 1
# And now fill in information for every day of the month
for { set current_date $first_julian_date } { $current_date <= $last_julian_date } {incr current_date } {
    if { [info exists users_hours($current_date)] && ![empty_string_p $users_hours($current_date)] } {
 	set html [util_decode $users_hours($current_date) 1 "1 hour" "$users_hours($current_date) hours"]
	set hours_for_this_week [expr $hours_for_this_week + $users_hours($current_date)]
    } else {
	set html "<font color=#666666><em>none</em></font>"
    }
    if { $looking_at_self_p } {
	set html "<a href=ae.tcl?[export_url_vars on_which_table]&julian_date=[ns_urlencode $current_date]>$html</a>"
    }

    if { $first_day == 7 && $hours_for_this_week > 0} {
	set html "
<br>
<table width=100% cellpadding=0 border=0 cellspacing=0>
<tr>
   <td align=right>[ad_partner_default_font "size=-1"]<a href=week.tcl?julian_date=[ns_urlencode $current_date]&[export_url_vars user_id on_which_table]>Week total: $hours_for_this_week</a></font></td>
</tr>
<tr>
   <td align=left>$html</td>
</tr>
</table>
"
    } else {
	set html "<p>&nbsp;<br>$html"
    }
    ns_set put $calendar_details $current_date $html
    
    # we keep track of the day of the week we are on
    incr first_day
    if { $first_day > 7 } {
	set first_day 1
	set hours_for_this_week 0.0
    }
}
    
set prev_month_template "<font color=white>&lt;</font> <a href=\"index.tcl?[export_url_vars user_id]&date=\$ansi_date\"><font color=white>\$prev_month_name</font></a>"
set next_month_template "<a href=\"index.tcl?[export_url_vars user_id]&date=\$ansi_date\"><font color=white>\$next_month_name</font></a> <font color=white>&gt;</font>"

set day_bgcolor "#efefef"
set day_number_template "<!--\$julian_date-->[ad_partner_default_font "size=-1"]\$day_number</font>"

set page_body [calendar_basic_month -calendar_details $calendar_details -next_month_template $next_month_template -prev_month_template $prev_month_template -day_number_template $day_number_template -day_bgcolor $day_bgcolor -date $date -prev_next_links_in_title 1 -fill_all_days 1 -empty_bgcolor "#cccccc"]

ns_return 200 text/html [ad_partner_return_template]
