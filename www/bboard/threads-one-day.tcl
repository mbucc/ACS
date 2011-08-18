# $Id: threads-one-day.tcl,v 3.0 2000/02/06 03:34:48 ron Exp $
set_the_usual_form_variables

# topic_id, topic, kickoff_date, maybe julian_date

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if { [bboard_get_topic_info] == -1 } {
    return
}


if { [info exists julian_date] && ![empty_string_p $julian_date] } {
    set kickoff_date [calendar_convert_julian_to_ansi $julian_date]
}

set pretty_date [util_AnsiDatetoPrettyDate $kickoff_date]

ReturnHeaders

ns_write "[bboard_header "$topic threads started on $pretty_date"]

<h2>Threads started on $pretty_date</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] [list "threads-by-day.tcl?[export_url_vars topic topic_id kickoff_date]" "Threads by Day"] "One Day"]

<hr>

Forum:  $topic

<ul>

"

set approved_clause ""
set selection [ns_db select $db "select msg_id, one_line, sort_key, email, first_names || ' ' || last_name as name, users.user_id as poster_id
from bboard, users 
where topic_id = $topic_id $approved_clause
and bboard.user_id = users.user_id 
and refers_to is null
and trunc(posting_time) = '$kickoff_date'
order by sort_key"]

set items ""
set n_rows 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr n_rows 
    append items "<li><a href=\"[bboard_msg_url $presentation_type $msg_id $topic]\">$one_line</a> ($name)\n"
}

if { $n_rows == 0 } {
    ns_write "no new threads were started on $pretty_date"
} else {
    ns_write $items
}

ns_write "

</ul>

[bboard_footer]
"
