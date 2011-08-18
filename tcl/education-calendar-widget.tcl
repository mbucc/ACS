#
# /tcl/education-calender-widget.tcl 
# Oct 1999 by aileen@arsdigita.com
#
# This is an adaptation of the im-calendar-widget by gregh and dvr
#

proc edu_calendar_get_info_from_db {db { date "" } } {

    if [empty_string_p $date] {
        set ora_date sysdate
    } else {
        set ora_date "to_date('$date')"
    }

    # This query gets us all of the date information we need to 
    # calculate the calendar, including the name of the month, the 
    # year, the julian date of the first of the month, the day of the 
    # week of the first day of the month, the day number of the last 
    # day (28, 29, 30 ,31) and a month string of the next and 
    # previous months

    set selection [ns_db 1row $db "
select
    to_char($ora_date, 'fmMonth') as month,
    to_char($ora_date, 'YYYY') as year,
    to_char(trunc($ora_date, 'Month'), 'D') as first_day_of_month,
    to_char(trunc($ora_date, 'Month'), 'J')
        as first_julian_date_of_month,
    to_char(last_day($ora_date), 'DD') as num_days_in_month,
    --to_char($ora_date, 'J') as current_julian_date,
    --to_char($ora_date, 'D') as current_day_of_week,
    --to_char($ora_date, 'DD') as current_day_of_month,
    to_char(last_day(add_months($ora_date, -1)), 'DD') 
        as days_in_last_month,
    add_months($ora_date, 1) as next_month,
    to_char(add_months($ora_date, 1), 'fmMonth') as next_month_name,
    add_months($ora_date, -1) as prev_month,
    to_char(add_months($ora_date, -1), 'fmMonth') as prev_month_name
from dual"]

    set_variables_after_query

    ns_set put $selection first_julian_date \
        [expr $first_julian_date_of_month + 1 - $first_day_of_month]

    ns_set put $selection first_day \
        [expr $days_in_last_month + 2 - $first_day_of_month]

    ns_set put $selection last_julian_date_in_month \
        [expr $first_julian_date_of_month + $num_days_in_month - 1]

    set days_in_next_month [expr 7 - (($num_days_in_month + $first_day_of_month - 1) % 7)]

    if {$days_in_next_month == 7} {
        set days_in_next_month 0
    }

    ns_set put $selection last_julian_date [expr $first_julian_date_of_month + $num_days_in_month - 1 + $days_in_next_month]

    set last_julian_date [expr $first_julian_date_of_month + $num_days_in_month - 1 + $days_in_next_month]

    return $selection
}

proc edu_calendar_basic_month {db func {set_up_func ""} {date ""}} {

    set bg_color [ad_parameter HeaderBGColor portals]
    set days_of_week "Sunday Monday Tuesday Wednesday Thursday Friday Saturday" 
    set large_calendar_p 1
    set master_bgcolor $bg_color
    set header_bgcolor $bg_color
    set header_text_color "white" 
    set header_text_size "2"     
    
    set day_number_template $func

    if ![info exists day_number_template] {
        set day_number_template {<!--\$julian_date--><font size=1>\$day_number</font>} 
    }

    set day_header_size 2
    set day_header_bgcolor "#666666" 
    set calendar_width "100%" 
    set day_bgcolor "#DDDDDD" 
    set day_text_color "white" 
    set empty_bgcolor "white"  
    set next_month_template ""   
    set prev_month_template ""
    set calendar_details ""

    set selection [edu_calendar_get_info_from_db $db $date]
    set_variables_after_query

    if ![empty_string_p set_up_func] {
        eval $set_up_func
    }

    if { $calendar_details == "" } {
	set calendar_details [ns_set create calendar_details]
    }

    set month_heading [format "%s %s" $month $year]

    set extra_url_vars ""
    if [info exists variables_to_pass] {
        foreach var $variables_to_pass {
           append extra_url_vars "$var=[ns_urlencode [value_if_exists $var]]&"
        }
    }

    set next_month_url "/portals/calendar.tcl?date=$next_month&$extra_url_vars"
    set prev_month_url "/portals/calendar.tcl?date=$prev_month&$extra_url_vars"

    # Write out the header and the days of the week
    append output "
<a href=/calendar/post-new.tcl?scope=user>Add personal event</a>
<p>
<table bgcolor=$master_bgcolor cellpadding=3 cellspacing=1 border=0 width=$calendar_width>
<TR>
<TD BGCOLOR=$header_bgcolor COLSPAN=7>

 <TABLE WIDTH=100% BORDER=0>
 <TR>
 <TD ALIGN=LEFT><FONT COLOR=WHITE>&lt; <A HREF=$prev_month_url><FONT COLOR=WHITE>$prev_month_name</FONT></A></FONT></TD>
 <TD align=center><font size=$header_text_size color=$header_text_color><b>$month_heading</b></font></TD>
 <TD ALIGN=RIGHT><FONT COLOR=WHITE><A HREF=$next_month_url><FONT COLOR=WHITE>$next_month_name</FONT></A> &gt;</FONT></TD>
 </TR>
 </TABLE>

</td>
</tr>
<tr bgcolor=$day_header_bgcolor>"

    foreach day_of_week $days_of_week {
        append output "<td width=14% align=center><font face=\"Verdana,Arial,Helvetica\" size=$day_header_size color=$day_text_color><b>$day_of_week</b></font></td>"
    }

    append output "</tr>\n<tr>\n"

    set day_of_week 1
    set julian_date $first_julian_date
    set day_number $first_day

    while {1} {

        if {$julian_date < $first_julian_date_of_month} {
            set before_month_p 1
            set after_month_p 0
        } elseif {$julian_date > $last_julian_date_in_month} {
            set before_month_p 0
            set after_month_p 1
        } else {
            set before_month_p 0
            set after_month_p 0
        }

        if {$julian_date == $first_julian_date_of_month} {
            set day_number 1
        } elseif {$julian_date > $last_julian_date} {
            break
        } elseif {$julian_date == [expr $last_julian_date_in_month +1]} {
            set day_number 1
        }

	if { $day_of_week == 1} {
	    append output "\n<tr>\n"
	}

        eval $day_number_template

        append output $square

	incr day_of_week
	incr julian_date
        incr day_number

	if { $day_of_week > 7 } {
	    set day_of_week 1
	    append output "</tr>\n"
	}
    }

    append html "</TR>"

    if { $prev_month_template != "" } { 

	set ansi_date [ns_urlencode $prev_month]
	set prev_month_url [subst $prev_month_template]
    }

    if { $next_month_template != "" } {

	set ansi_date [ns_urlencode $next_month]
	set next_month_url [subst $next_month_template]
    }

#    append output "
#    <tr bgcolor=white>
#    <td align=center colspan=7>$prev_month_url$next_month_url</td>
#    </tr>"

    append output "</table>"

    return $output

}

proc_doc edu_calendar_for_portal {db {date ""}} "outputs a calendar for the portal" {
    set class_prep_function {
	set user_id [ad_verify_and_get_user_id]
	
	# get class related events
	set selection [ns_db select $db "
	select to_char(due_date, 'J') as due_date, task_type, task_name, task_id
	from edu_student_tasks t, edu_classes c, users, user_group_map m
	where t.class_id=c.class_id
	and users.user_id=m.user_id
	and m.user_id=$user_id
	and m.group_id=c.class_id
	and due_date between to_date($first_julian_date, 'J') 
        and to_date($last_julian_date, 'J')
	and t.active_p='t'
	group by due_date, task_type, task_name, task_id
	"]
	
	array set hours_for_days {}
	
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    
	    if {![info exists hours_for_days($due_date)] || $hours_for_days($due_date)==""} {
		set hours_for_days($due_date) "<font size=-2>"
	    }

	    append hours_for_days($due_date) "<li><a href=[edu_url]class/${task_type}-info.tcl?${task_type}_id=$task_id>$task_name"

	    if {$task_type!="exam"} {
		append hours_for_days($due_date) " due"
	    }

	    append hours_for_days($due_date) "</a>"
	}
	
	# now get personal events
	set selection [ns_db select $db "
	select to_char(start_date, 'J') as start_date, title, calendar_id, c.category_id
	from calendar c, calendar_categories cc
	where $user_id=cc.user_id
	and lower(cc.scope)='user'
	and c.category_id=cc.category_id
	and start_date between to_date($first_julian_date, 'J') 
        and to_date($last_julian_date, 'J') 
	"]
	
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    
	    if {![info exists hours_for_days($start_date)] || $hours_for_days($start_date)==""} {
		set hours_for_days($start_date) "<font size=-2>"
	    }

	    append hours_for_days($start_date) "<li><a href=/calendar/item.tcl?calendar_id=$calendar_id&scope=user>$title</a>"
	}
	
	
	set variables_to_pass [list]
	
    }
    
    set day_number_template {
	
	if {$before_month_p || $after_month_p} {
	    set bg_color "#cccccc"
	} elseif {($day_of_week == 1) || ($day_of_week == 7)} {
	    set bg_color "#efefef"
	} else {
	    set bg_color "#efefef"
	}
	
	set square "<TD VALIGN=TOP WIDTH=14% BGCOLOR=$bg_color>"
	
	if {![info exists hours_for_this_week] || ($day_of_week == 1)} {
	    set hours_for_this_week 0
	}
	
	append square "
	<TABLE WIDTH=100% BORDER=0 CELLPADDING=0 CELLSPACING=0>
	<TR><TD ALIGN=RIGHT><FONT SIZE=-1 FACE=Arial>$day_number</FONT></TD></TR>
	<TR>"
	
	if [info exists hours_for_days($julian_date)] {
	    set hours_for_today $hours_for_days($julian_date) 
	    set linktext "$hours_for_today"
	} else {
	    set linktext <BR>
	}
	
	append square "<TD ALIGN=RIGHT VALIGN=BOTTOM HEIGHT=30><BR></TD></TR>\n"
	
	set hours_link "$linktext"
	
	append square "<TR>
	<TD>
	"
	
	if ![empty_string_p $linktext] {
	    append square "<FONT SIZE=-1 FACE=Arial>$hours_link</FONT>"
	}
	
	append square "</TD>
	</TR>
	</TABLE>
	</TD>
	"
	
    }
    
    return [edu_calendar_basic_month $db $day_number_template $class_prep_function $date]
}



proc value_if_exists {variable} {
    upvar $variable $variable
    
    if {[info exists $variable]} {
	return [set $variable]
    } else {
	return ""
    }
}
