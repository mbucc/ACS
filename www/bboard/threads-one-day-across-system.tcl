# $Id: threads-one-day-across-system.tcl,v 3.0 2000/02/06 03:34:47 ron Exp $
# /bboard/threads-one-day-across-system.tcl
#
# by philg@mit.edu on October 8, 1999
#


set_the_usual_form_variables

# kickoff_date, maybe julian_date

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if { [info exists julian_date] && ![empty_string_p $julian_date] } {
    set kickoff_date [calendar_convert_julian_to_ansi $julian_date]
}

set pretty_date [util_AnsiDatetoPrettyDate $kickoff_date]

ReturnHeaders

ns_write "[bboard_header "Threads started on $pretty_date"]

<h2>Threads started on $pretty_date</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list "statistics.tcl" "Statistics"] [list "threads-by-day.tcl?[export_url_vars kickoff_date]" "Threads by Day"] "One Day"]

<hr>

<ul>

"

set selection [ns_db select $db "select bboard.topic, msg_id, one_line, sort_key, email, first_names || ' ' || last_name as name, users.user_id as poster_id, bboard_topics.presentation_type
from bboard, users, bboard_topics
where bboard.user_id = users.user_id 
and bboard.topic = bboard_topics.topic
and refers_to is null
and bboard_topics.restricted_p = 'f' 
and bboard_topics.restrict_to_workgroup_p = 'f'
and trunc(posting_time) = '$kickoff_date'
order by upper(bboard_topics.topic), sort_key"]

set items ""
set n_rows 0
set last_topic ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr n_rows 
    if { $topic != $last_topic } {
	set last_topic $topic
	append items "\n<h4>$topic</h4>\n"
    }
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
