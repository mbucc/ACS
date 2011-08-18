# $Id: monthly.tcl,v 3.0 2000/02/06 03:35:54 ron Exp $
set_the_usual_form_variables 0

# maybe date

set page_title [ad_parameter SystemName calendar "Calendar"]

ReturnHeaders

ns_write "[ad_header $page_title]

<h2>$page_title</h2>

[ad_context_bar_ws "Calendar"]

<hr>

"

set db [ns_db gethandle]
set calendar_details [ns_set create calendar_details]

 if {![info exists date] || [empty_string_p $date]} {
    set date [database_to_tcl_string $db "select sysdate from dual"]
}

# get all the calandar entries for this month 

set selection [ns_db select $db "select calendar.title, 
calendar.calendar_id, to_char(start_date,'J') as julian_start_date, 
to_char(end_date,'J') as julian_end_date  from calendar
where to_char(start_date, 'yyyy') = to_char(to_date('$date','yyyy-mm-dd'),'yyyy') 
and to_char(start_date, 'mm') = to_char(to_date('$date','yyyy-mm-dd'),'mm') 
and approved_p = 't'"]


while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    for {set x $julian_start_date} {$x <= $julian_end_date} {incr x} {
	ns_set put $calendar_details $x "<a href=\"item.tcl?calendar_id=$calendar_id\">$title</a>\n <br>"
    }
}


#### We include special calendar information for intranet enabled 
#### acs installations that have requested vacations to be in the calendar

if { [ad_parameter IntranetEnabledP intranet 0] && [ad_parameter DisplayVacationsOnCalendar intranet 0] } {
    set absence_types [ad_parameter AbsenceTypes pvt "sick travel vacation"]
    set vacation_key "<table><tr bgcolor=#DDDDDD><td>KEY:"
    foreach a_type $absence_types {
	append vacation_key "<td>$a_type ([string range $a_type 0 0])"
    }

    ns_write "$vacation_key</table>"

    set selection [ns_db select $db "select users.first_names || ' ' || substr(last_name, 0,1) as name, email, decode(substr(vacation_type,0,1),null,'v', substr(vacation_type,0,1)) as vt, vacation_type, users.user_id , to_char(start_date,'J') as julian_start_date, 
to_char(end_date,'J') as julian_end_date  
from user_vacations, users
where users.user_id = user_vacations.user_id
and to_char(start_date, 'yyyy') = to_char(to_date('$date','yyyy-mm-dd'), 'yyyy') 
and to_char(start_date, 'mm') = to_char(to_date('$date','yyyy-mm-dd'), 'mm')"]


    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	for {set x $julian_start_date} {$x <= $julian_end_date} {incr x} {
	    ns_set put $calendar_details $x "<font size=-1><a href=[im_url_stub]/users/view.tcl?[export_url_vars user_id]>[set name]</a> ($vt)</font> "
	}
    }
}


set prev_month_template "<font color=white>&lt;</font> <a href=\"monthly.tcl?date=\$ansi_date\"><font color=white>\$prev_month_name</font></a>"
set next_month_template "<a href=\"monthly.tcl?date=\$ansi_date\"><font color=white>\$next_month_name</font></a> <font color=white>&gt;</font>"

ns_write "[calendar_basic_month -calendar_details $calendar_details  -next_month_template $next_month_template -prev_month_template $prev_month_template -date $date -prev_next_links_in_title 1]
"

if { [ad_parameter ApprovalPolicy calendar] == "open"} {
    ns_write "<p>\n<a href=\"post-new.tcl\">post an item</a>\n"
} elseif { [ad_parameter ApprovalPolicy calendar] == "wait"} {
    ns_write "<p>\n<a href=\"post-new.tcl\">suggest an item</a>\n"
}


ns_write "
[calendar_footer]
"

