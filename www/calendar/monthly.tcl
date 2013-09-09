# www/calendar/monthly.tcl
ad_page_contract {
    Displays a very pretty calendar!

    Number of queries: 5

    @author unknown
    @creation-date unknown
    @cvs-id monthly.tcl,v 3.6.2.7 2000/09/22 01:37:05 kevin Exp
} {
    { date "" }
    { viewing_group_id:naturalnum "" }
    { group_id:naturalnum "" }
}

# date is an Oracle keyword
set my_date $date

# Allow people to call this page with "group_id" - transfer it to 
# viewing_group_id to save the variable

## Why is *this* page all about the group_id?  Try finding mention of
## groups in *any* other page in this module. -MJS


if { [empty_string_p $viewing_group_id] && ![empty_string_p $group_id] } {
    set viewing_group_id $group_id
}

set page_title [ad_parameter SystemName calendar "Calendar"]


set page_content "
[ad_header $page_title]

<h2>$page_title</h2>

[ad_context_bar_ws "Calendar"]

<hr>

"

set db [ns_db gethandle]

set query_team_groups "
select group_id, group_name
from user_groups 
where parent_group_id = [im_team_group_id]
"

set team_list [list "0" "All"]

db_foreach team_groups $query_team_groups {

    lappend team_list $group_id $group_name
}

set team_slider [im_slider viewing_group_id $team_list $viewing_group_id "start_idx group_id"]

set office_list [list "0" "All"]

set query_office_groups "
select group_id, group_name
from user_groups 
where parent_group_id = [im_office_group_id]"

db_foreach office_groups $query_office_groups {
    lappend office_list $group_id $group_name
}

set office_slider [im_slider viewing_group_id $office_list $viewing_group_id "start_idx group_id"]

set calendar_details [ns_set create calendar_details]

## Do we really need to go to the database for the *date?* -MJS

if {![info exists my_date] || [empty_string_p $my_date]} {
    set my_date [db_string today "select sysdate from dual"]
}

# get all the calendar entries for this month 

# calendar items aren't group-specific, otherwise there would be a filter here

## And then pass the date back in again?? -MJS

set query_calendar_items "
select calendar.title, 
       calendar.calendar_id, 
       to_char(start_date,'J') as julian_start_date, 
       to_char(end_date,'J') as julian_end_date  
from   calendar
where  start_date <= last_day(to_date(:my_date,'yyyy-mm-dd'))
and    end_date >= trunc(to_date(:my_date,'yyyy-mm-dd'),'Month') 
and    approved_p = 't'"

db_foreach calendar_items $query_calendar_items {

    for {set x $julian_start_date} {$x <= $julian_end_date} {incr x} {
	ns_set put $calendar_details $x "<a href=\"item?calendar_id=$calendar_id\">$title</a>\n <br>"
    }
}


#### We include special calendar information for intranet enabled 
#### acs installations that have requested vacations to be in the calendar

if { [ad_parameter IntranetEnabledP intranet 0] && \
	[ad_parameter DisplayVacationsOnCalendar intranet 0] && \
	[im_user_is_authorized_p [ad_get_user_id]] } {
    
    
    # the office and team select lists are inside of this if statement because,
    # at least for now, the only thing they affect is vacations
    
    set absence_types [ad_parameter AbsenceTypes pvt "sick travel vacation personal"]
    set vacation_key "<table>
    <tr bgcolor=#DDDDDD>
    <td>KEY:</td>
    "

    foreach a_type $absence_types {
	append vacation_key "  <td>$a_type ([string range $a_type 0 0])</td>\n"
    }
    
    
    append page_content "<table width=100% cellpadding=0 cellspacing=2 border=0>
    <tr bgcolor=eeeeee>
    <th>Office</th>
    <th>Team</th>
    </tr>
    <tr>
    <td align=center valign=top><font size=-1>$office_slider</font></td>
    <td align=center valign=top><font size=-1>$team_slider</font></td>
    </tr>
    </table>
    
    $vacation_key
    </tr>
    </table>
    "

    
    # if viewing_group_id is set, only show vacations for users in that group
    set query_user_vacations "
    select users.first_names || ' ' || substr(last_name, 0,1) as name, 
           email, 
           decode(substr(vacation_type,0,1),null,'v', substr(vacation_type,0,1)) as vt, 
           vacation_type, 
           users.user_id, 
           to_char(start_date,'J') as julian_start_date, 
           to_char(end_date,'J') as julian_end_date  
    from   user_vacations, 
           users
    where  users.user_id = user_vacations.user_id
    [util_decode $viewing_group_id "" "" "and ad_group_member_p(users.user_id, '$viewing_group_id') = 't'"]
    and    start_date  <= last_day(to_date(:my_date,'yyyy-mm-dd')) 
    and    end_date >= trunc(to_date(:my_date,'yyyy-mm-dd'), 'Month')"
    
    db_foreach user_vacations $query_user_vacations {
	
	for {set x $julian_start_date} {$x <= $julian_end_date} {incr x} {
	    ns_set put $calendar_details $x "<font size=-1><a href=[im_url_stub]/users/view?[export_url_vars user_id]>[set name]</a> ($vt)</font>"
	}
    }
}


set prev_month_template "
<font color=white>&lt;</font> 
<a href=\"monthly?date=\$ansi_date&[export_url_vars viewing_group_id]\">
<font color=white>\$prev_month_name</font></a>"

set next_month_template "
<a href=\"monthly?date=\$ansi_date&[export_url_vars viewing_group_id]\">
<font color=white>\$next_month_name</font></a> <font color=white>&gt;</font>"

append page_content "
[calendar_basic_month -calendar_details $calendar_details  -next_month_template $next_month_template -prev_month_template $prev_month_template -date $my_date -prev_next_links_in_title 1]
"


if { [ad_parameter ApprovalPolicy calendar] == "open"} {

    append page_content "<p>\n<a href=\"post-new\">post an item</a>\n"

} elseif { [ad_parameter ApprovalPolicy calendar] == "wait"} {

    append page_content "<p>\n<a href=\"post-new\">suggest an item</a>\n"

}

append page_content "[calendar_footer]"

doc_return  200 text/html $page_content

## END FILE monthly.tcl





