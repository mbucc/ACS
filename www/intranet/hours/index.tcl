# /www/intranet/hours/index.tcl

ad_page_contract {
    Calendar format display of user's hours with links 
    to log more hours, if the user is looking at him/
    herself

    @param on_which_table table we're viewing hours against
    @param date day in ansi format in the month we're currently viewing
    @param julian_date day in julian format in the month we're currently viewing
    @param user_id the user for whom we're viewing hours. Defaults to currently logged in user.
    @param group_id The user group for which we're viewing hours. Defaults to all groups.
    @param return_url Return URL
 
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @cvs-id index.tcl,v 3.11.2.10 2000/10/26 19:24:23 mbryzek Exp
   
} {
    { on_which_table "im_projects" }
    { date "" }
    { julian_date "" }
    { user_id:integer "" }
    { group_id:integer "" }
    { return_url "" }
}

set caller_id [ad_get_user_id]

if { [empty_string_p $user_id] } {
    if {$caller_id} { 
        set user_id $caller_id
    } else {
        ad_maybe_redirect_for_registration
    }
}

if {$user_id == $caller_id} {
    # Can do anything to your own hours :)
    set user_admin_p 1
} else {
    set user_admin_p [im_is_user_site_wide_or_intranet_admin $caller_id]
}


if { ![db_0or1row user_name {
    select u.first_names || ' ' || u.last_name as user_name
    from users u 
    where u.user_id = :user_id}] } {

    ad_return_error "User $user_id does not exist" "We couldn't find the user #$user_id in the database. Please back up, reload, and try again."
    return
}

set page_title "Hours by $user_name"
set context_bar [ad_context_bar_ws "Hours"]

if { ![empty_string_p $group_id] } {
    set project_name [db_string project_name \
	    "select group_name from user_groups where group_id = :group_id"]
    append page_title " on $project_name"
    set project_restriction "and group_id = :group_id"
} else {
    set project_restriction ""
}

# Default to today if there is no date specified
if { [empty_string_p $date] } {
    if { ![empty_string_p $julian_date] } {
	set date [db_string julian_date_select \
		"select to_char( to_date(:julian_date,'J'), 'YYYY-MM-DD') from dual"]
    } else {
	set date [db_string ansi_date_select \
		"select to_char( sysdate, 'YYYY-MM-DD') from dual"]
    }
} 

set calendar_details [ns_set create calendar_details]

# figure out the first and last julian days in the month
# This call defines a whole set of variables in our environment
calendar_get_info_from_db $date

# Grab all the hours from im_hours
set sql "select to_char(day, 'J') as julian_date, sum(hours) as hours
           from im_hours 
          where user_id = :user_id
            and day between to_date(:first_julian_date, 'J') 
                            and to_date(:last_julian_date, 'J') $project_restriction
       group by to_char(day, 'J')"

db_foreach hours_logged $sql {
    set users_hours($julian_date) $hours
}

# Choose between daily/weekly time entry screen
if { [string compare [ad_parameter TimeEntryScreen intranet "daily"] "weekly"] == 0 } {
    set target "time-entry"
} else {
    set target "ae"
}


set hours_for_this_week 0.0
set first_day 1
set absence_list [absence_list_for_user_and_time_period $user_id $first_julian_date $last_julian_date]
set absence_index 0
# And now fill in information for every day of the month
for { set current_date $first_julian_date } { $current_date <= $last_julian_date } {incr current_date } {
    if { [info exists users_hours($current_date)] && ![empty_string_p $users_hours($current_date)] } {
 	set html [util_decode $users_hours($current_date) 1 "1 hour" "$users_hours($current_date) hours"]
	set hours_for_this_week [expr $hours_for_this_week + $users_hours($current_date)]
    } else {
	set html [lindex $absence_list $absence_index]
        if { [string equal $html work] } {
            set html "<font color=#666666><em>log hours</em></font>"
        }
    }
    if { $user_admin_p } {
	set html "<a href=$target?[export_url_vars user_id on_which_table return_url]&julian_date=[ad_urlencode $current_date]>$html</a>"
    }

    if { $first_day == 7 && $hours_for_this_week > 0} {
	set html "
	<br>
	<table width=100% cellpadding=0 border=0 cellspacing=0>
	<tr>
	<td align=right><font size=-1><a href=week?julian_date=[ns_urlencode $current_date]&[export_url_vars user_id on_which_table]>Week total: $hours_for_this_week</a></font></td>
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
    incr absence_index
}

set prev_month_template "<font color=white>&lt;</font> <a href=\"index?[export_url_vars user_id]&date=\$ansi_date\"><font color=white>\$prev_month_name</font></a>"
set next_month_template "<a href=\"index?[export_url_vars user_id]&date=\$ansi_date\"><font color=white>\$next_month_name</font></a> <font color=white>&gt;</font>"

set day_bgcolor "#efefef"
set day_number_template "<!--\$julian_date--><font size=-1>\$day_number</font>"

set page_body [calendar_basic_month -calendar_details $calendar_details -next_month_template $next_month_template -prev_month_template $prev_month_template -day_number_template $day_number_template -day_bgcolor $day_bgcolor -date $date -prev_next_links_in_title 1 -fill_all_days 1 -empty_bgcolor "#cccccc"]



doc_return  200 text/html [im_return_template]
