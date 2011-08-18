# $Id: ad-calendar-widget.tcl,v 3.0 2000/02/06 03:12:12 ron Exp $
#
# ad-calendar-widget.tcl
#

# by gregh@arsdigita.com in June 1999
# reviewed by philg@mit.edu, June 1999 for release with ACS 2.0

# documentation and example in /doc/calendar-widget.html 

util_report_library_entry

# Calculates various dates required by the calendar_basic_month procedure
#
# Requires an ANSI date, in the format "YYYY-MM-DD"
proc calendar_get_info_from_db { { date "" } } {
    set db [ns_db gethandle subquery]

    # If no date was passed in, let's set it to today
    if { $date == "" } {
	set date [database_to_tcl_string $db "select trunc(sysdate) from dual"]
    }

    # This query gets us all of the date information we need to calculate
    # the calendar, including the name of the month, the year, the julian date
    # of the first of the month, the day of the week of the first day of the
    # month, the day number of the last day (28, 29, 30 ,31) and
    # a month string of the next and previous months
    set month_info_query "select to_char(trunc(to_date('$date', 'yyyy-mm-dd'), 'Month'), 'fmMonth') as month, 
    to_char(trunc(to_date('$date', 'yyyy-mm-dd'), 'Month'), 'YYYY') as year, 
    to_char(trunc(to_date('$date', 'yyyy-mm-dd'), 'Month'), 'J') as first_julian_date_of_month, 
    to_char(last_day(to_date('$date', 'yyyy-mm-dd')), 'DD') as num_days_in_month,
    to_char(trunc(to_date('$date', 'yyyy-mm-dd'), 'Month'), 'D') as first_day_of_month, 
    to_char(last_day(to_date('$date', 'yyyy-mm-dd')), 'DD') as last_day,
    trunc(add_months(to_date('$date', 'yyyy-mm-dd'), 1)) as next_month,
    trunc(add_months(to_date('$date', 'yyyy-mm-dd'), -1)) as prev_month,
    trunc(to_date('$date', 'yyyy-mm-dd'), 'yyyy') as beginning_of_year,
    to_char(last_day(add_months(to_date('$date', 'yyyy-mm-dd'), -1)), 'DD') as days_in_last_month,
    to_char(add_months(to_date('$date', 'yyyy-mm-dd'), 1), 'fmMonth') as next_month_name,
    to_char(add_months(to_date('$date', 'yyyy-mm-dd'), -1), 'fmMonth') as prev_month_name
    from dual"

    set selection [ns_db 1row $db $month_info_query]
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

    ns_set put $selection last_julian_date \
	    [expr $first_julian_date_of_month + $num_days_in_month - 1 + $days_in_next_month]
    ns_db releasehandle $db

    return $selection
}

proc_doc calendar_convert_julian_to_ansi { date } "Return an ANSI date for a Julian date" {
    set db [ns_db gethandle subquery]

    set output [database_to_tcl_string $db "select trunc(to_date('$date', 'J')) from dual"]

    ns_db releasehandle $db

    return $output
}


ad_proc calendar_basic_month { {-calendar_details "" -date "" -days_of_week "Sunday Monday Tuesday Wednesday Thursday Friday Saturday" -large_calendar_p 1 -master_bgcolor "black" -header_bgcolor "black" -header_text_color "white" -header_text_size "+2" -day_number_template {<!--\$julian_date--><font size=1>\$day_number</font>} -day_header_size 2 -day_header_bgcolor "#666666" -calendar_width "100%" -day_bgcolor "#DDDDDD" -day_text_color "white" -empty_bgcolor "white"  -next_month_template ""   -prev_month_template "" -prev_next_links_in_title 0 -fill_all_days 0 } } "Returns a calendar for a specific month, with details supplied by Julian date. Defaults to this month.

To specify details for the individual days (if large_calendar_p is set) put data in an ns_set calendar_details.  The key is the Julian date of the day, and the value is a string (possibly with HTML formatting) that represents the details.
" {

    set selection [calendar_get_info_from_db $date]
    set_variables_after_query

    if { $calendar_details == "" } {
	set calendar_details [ns_set create calendar_details]
    }

    set day_of_week $first_day_of_month
    set julian_date $first_julian_date

    set month_heading [format "%s %s" $month $year]
    set next_month_url ""
    set prev_month_url ""

    if { $prev_month_template != "" } { 
	set ansi_date [ns_urlencode $prev_month]
	set prev_month_url [subst $prev_month_template]
    }
    if { $next_month_template != "" } {
	set ansi_date [ns_urlencode $next_month]
	set next_month_url [subst $next_month_template]
    }

    # We offer an option to put the links to next and previous months in the title bar
    if { $prev_next_links_in_title == 0 } {
	set title "<td colspan=7 align=center><font size=$header_text_size color=$header_text_color><b>$month_heading</b></font></td>"
    } else {
	set title "
<td colspan=7>
  <table width=100% cellpadding=0 cellspacing=0 border=0>
  <tr>
    <td align=left>$prev_month_url</td>
    <td align=center><font size=$header_text_size color=$header_text_color><b>$month_heading</b></font></td>
    <td align=right>$next_month_url</td>
  </tr>
  </table>
</td>
"
    }

    # Write out the header and the days of the week
    append output "<table bgcolor=$master_bgcolor cellpadding=3 cellspacing=1  border=0 width=$calendar_width>
    <tr bgcolor=$header_bgcolor>
    $title
    </tr>
    <tr bgcolor=$day_header_bgcolor>"


    foreach day_of_week $days_of_week {
	append output "<td width=14% align=center><font face=\"Verdana,Arial,Helvetica\" size=$day_header_size color=$day_text_color><b>$day_of_week</b></font></td>"

    }

    append output "</tr><tr>"

    if { $fill_all_days == 0 } {
	for { set n 1} { $n < $first_day_of_month } { incr n } {
	    append output "<td bgcolor=$empty_bgcolor align=right valign=top></td>"
	}
    }

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

	set skip_day 0
	if {$before_month_p || $after_month_p} {
	    append output "<td bgcolor=$empty_bgcolor align=right valign=top>&nbsp;"
	    if { $fill_all_days == 0 } {
		set skip_day 1
	    } else {
		append output "[subst $day_number_template]&nbsp;"
	    }
	} else {
	    append output "<td bgcolor=$day_bgcolor align=right valign=top>[subst $day_number_template]&nbsp;"
	}

	if { (! $skip_day) && $large_calendar_p == 1 } {
	    append output "<div align=left>"

	    set calendar_day_index [ns_set find $calendar_details $julian_date]
	    
	    while { $calendar_day_index >= 0 } {
		    
		set calendar_day [ns_set value $calendar_details $calendar_day_index]
		ns_set delete $calendar_details $calendar_day_index
		
		append output "$calendar_day"
		
		set calendar_day_index [ns_set find $calendar_details $julian_date]
		
	    }
	    
	    append output "</div>"
	}

	append output "</td>\n"

	incr day_of_week
	incr julian_date
        incr day_number

	if { $day_of_week > 7 } {
	    set day_of_week 1
	    append output "</tr>\n"
	}
    }


    # There are two ways to display previous and next month link - this is the default
    if { $prev_next_links_in_title == 0 } {
	append output "
    <tr bgcolor=white>
    <td align=center colspan=7>$prev_month_url$next_month_url</td>
    </tr>"
    }

    append output "</table>"

    return $output

}

ad_proc calendar_small_month { {-calendar_details "" -date "" -days_of_week "S M T W T F S" -large_calendar_p 0 -master_bgcolor "black" -header_bgcolor "black" -header_text_color "white" -header_text_size "+1" -day_number_template {<!--\$julian_date--><font size=1>\$day_number</font>} -day_header_size 1 -day_header_bgcolor "#666666" -calendar_width 0 -day_bgcolor "#DDDDDD" -day_text_color "white" -empty_bgcolor "white"  -next_month_template ""   -prev_month_template ""  } } "Returns a small calendar for a specific month. Defaults to this month." {


    return [calendar_basic_month -calendar_details $calendar_details -date $date -days_of_week $days_of_week -large_calendar_p $large_calendar_p -master_bgcolor $master_bgcolor -header_bgcolor $header_bgcolor -header_text_color $header_text_color -header_text_size $header_text_size -day_number_template $day_number_template -day_header_size $day_header_size -day_header_bgcolor $day_header_bgcolor -calendar_width $calendar_width -day_bgcolor $day_bgcolor -day_text_color $day_text_color -empty_bgcolor $empty_bgcolor  -next_month_template $next_month_template   -prev_month_template $prev_month_template ]

}

ad_proc calendar_prev_current_next { {-calendar_details "" -date "" -days_of_week "S M T W T F S" -large_calendar_p 0 -master_bgcolor "black" -header_bgcolor "black" -header_text_color "white" -header_text_size "+1" -day_number_template {<!--\$julian_date--><font size=1>\$day_number</font>} -day_header_size 1 -day_header_bgcolor "#666666" -calendar_width 0 -day_bgcolor "#DDDDDD" -day_text_color "white" -empty_bgcolor "white"  -next_month_template ""   -prev_month_template ""  } } "Returns a calendar for a specific month, with details supplied by Julian date. Defaults to this month." {

    set output ""

    set selection [calendar_get_info_from_db $date]
    set_variables_after_query

    append output "<table><tr valign=top>\n"
    append output "<td>
    [calendar_small_month -calendar_details $calendar_details -date $prev_month -days_of_week $days_of_week -large_calendar_p $large_calendar_p -master_bgcolor $master_bgcolor -header_bgcolor $header_bgcolor -header_text_color $header_text_color -header_text_size $header_text_size -day_number_template $day_number_template -day_header_size $day_header_size -day_header_bgcolor $day_header_bgcolor -calendar_width $calendar_width -day_bgcolor $day_bgcolor -day_text_color $day_text_color -empty_bgcolor $empty_bgcolor  -next_month_template $next_month_template   -prev_month_template $prev_month_template ]</td>
    <td>
    [calendar_small_month -calendar_details $calendar_details -date $date -days_of_week $days_of_week -large_calendar_p $large_calendar_p -master_bgcolor $master_bgcolor -header_bgcolor $header_bgcolor -header_text_color $header_text_color -header_text_size $header_text_size -day_number_template $day_number_template -day_header_size $day_header_size -day_header_bgcolor $day_header_bgcolor -calendar_width $calendar_width -day_bgcolor $day_bgcolor -day_text_color $day_text_color -empty_bgcolor $empty_bgcolor  -next_month_template $next_month_template   -prev_month_template $prev_month_template ]
    </td>
    <td>
    [calendar_small_month -calendar_details $calendar_details -date $next_month -days_of_week $days_of_week -large_calendar_p $large_calendar_p -master_bgcolor $master_bgcolor -header_bgcolor $header_bgcolor -header_text_color $header_text_color -header_text_size $header_text_size -day_number_template $day_number_template -day_header_size $day_header_size -day_header_bgcolor $day_header_bgcolor -calendar_width $calendar_width -day_bgcolor $day_bgcolor -day_text_color $day_text_color -empty_bgcolor $empty_bgcolor  -next_month_template $next_month_template   -prev_month_template $prev_month_template ]
    </td>
    </table>\n"

    return $output
}


ad_proc calendar_small_year { {-calendar_details "" -date "" -days_of_week "S M T W T F S" -large_calendar_p 0 -master_bgcolor "black" -header_bgcolor "black" -header_text_color "white" -header_text_size "+1" -day_number_template {<!--\$julian_date--><font size=1>\$day_number</font>} -day_header_size 1 -day_header_bgcolor "#666666" -calendar_width 0 -day_bgcolor "#DDDDDD" -day_text_color "white" -empty_bgcolor "white"  -next_month_template ""   -prev_month_template ""  -width 2} } "Returns a year of small calendars given the starting month as a date.  Defaults to this month.  Data in calendar_details will be ignored." {


    if { $width < 1 || $width > 12 } {
	return "Width must be between 1 and 12"
    }

    set output "<table><tr valign=top>\n"
    set current_width 0

    for { set n 1 } { $n <= 12 } { incr n } {
	set selection [calendar_get_info_from_db $date]
	set_variables_after_query
	
	append output "<td>"

	append output "[calendar_small_month -calendar_details $calendar_details -date $date -days_of_week $days_of_week -large_calendar_p $large_calendar_p -master_bgcolor $master_bgcolor -header_bgcolor $header_bgcolor -header_text_color $header_text_color -header_text_size $header_text_size -day_number_template $day_number_template -day_header_size $day_header_size -day_header_bgcolor $day_header_bgcolor -calendar_width $calendar_width -day_bgcolor $day_bgcolor -day_text_color $day_text_color -empty_bgcolor $empty_bgcolor  -next_month_template $next_month_template   -prev_month_template $prev_month_template ]"
	append output "</td>\n"

	incr current_width

	if { $current_width == $width && $n != 12} {
	    set current_width 0
	    append output "</tr><tr valign=top>\n"
	}

	set date $next_month
    }

    append output "</tr></table>\n"

    return $output
}

ad_proc calendar_small_calendar_year { {-calendar_details "" -date "" -days_of_week "S M T W T F S" -large_calendar_p 0 -master_bgcolor "black" -header_bgcolor "black" -header_text_color "white" -header_text_size "+1" -day_number_template {<!--\$julian_date--><font size=1>\$day_number</font>} -day_header_size 1 -day_header_bgcolor "#666666" -calendar_width 0 -day_bgcolor "#DDDDDD" -day_text_color "white" -empty_bgcolor "white" -next_month_template "" -prev_month_template "" -width 2} } "Returns a calendar year of small calendars for the year of the passed in date.  Defaults to this year." {

    set selection [calendar_get_info_from_db $date]
    set_variables_after_query

    return [calendar_small_year -calendar_details $calendar_details -date $beginning_of_year -days_of_week $days_of_week -large_calendar_p $large_calendar_p -master_bgcolor $master_bgcolor -header_bgcolor $header_bgcolor -header_text_color $header_text_color -header_text_size $header_text_size -day_number_template $day_number_template -day_header_size $day_header_size -day_header_bgcolor $day_header_bgcolor -calendar_width $calendar_width -day_bgcolor $day_bgcolor -day_text_color $day_text_color -empty_bgcolor $empty_bgcolor  -next_month_template $next_month_template  -prev_month_template $prev_month_template  -width $width]
}


util_report_successful_library_load




