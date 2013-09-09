# /www/bboard/threads-one-day.tcl
ad_page_contract {

    @cvs-id threads-one-day.tcl,v 3.1.2.4 2000/09/22 01:36:56 kevin Exp
} {
    topic_id:integer
    topic
    kickoff_date:optional
    julian_date:optional
}

# -----------------------------------------------------------------------------

if { [bboard_get_topic_info] == -1 } {
    return
}


if { [info exists julian_date] && ![empty_string_p $julian_date] } {
    set kickoff_date [calendar_convert_julian_to_ansi $julian_date]
}

set pretty_date [util_AnsiDatetoPrettyDate $kickoff_date]

append page_content "
[bboard_header "$topic threads started on $pretty_date"]

<h2>Threads started on $pretty_date</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] [list "threads-by-day.tcl?[export_url_vars topic topic_id kickoff_date]" "Threads by Day"] "One Day"]

<hr>

Forum:  $topic

<ul>

"

db_foreach messages "
select msg_id, 
       one_line, 
       sort_key, 
       email, 
       first_names || ' ' || last_name as name, 
       users.user_id as poster_id
from   bboard, 
       users 
where  topic_id = :topic_id
and    bboard.user_id = users.user_id 
and    refers_to is null
and    trunc(posting_time) = :kickoff_date
order by sort_key" {

    append page_content "<li><a href=\"[bboard_msg_url $presentation_type $msg_id $topic]\">$one_line</a> ($name)\n"

} if_no_rows {
    append page_content "no new threads were started on $pretty_date"
}

append page_content "

</ul>

[bboard_footer]
"


doc_return  200 text/html $page_content