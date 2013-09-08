# /www/bboard/threads-one-day-across-system.tcl

ad_page_contract {
    
    @author philg@mit.edu
    @creation-date 8 Oct 1999
    @cvs-id threads-one-day-across-system.tcl,v 3.1.2.6 2000/09/22 01:36:56 kevin Exp
} {
    kickoff_date:optional
    julian_date:optional
}

# -----------------------------------------------------------------------------

# it's okay if the user isn't logged in; in that case they will only be shown 
# bboard topics with public read access.
set user_id [ad_verify_and_get_user_id]

if { [exists_and_not_null julian_date] } {
    set kickoff_date [calendar_convert_julian_to_ansi $julian_date]
}

set pretty_date [util_AnsiDatetoPrettyDate $kickoff_date]


append page_content "[bboard_header "Threads started on $pretty_date"]

<h2>Threads started on $pretty_date</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list "statistics.tcl" "Statistics"] [list "threads-by-day.tcl?[export_url_vars kickoff_date]" "Threads by Day"] "One Day"]

<hr>

<ul>

"

set last_topic ""

db_foreach messages_for_one_day "
select topic, 
       msg_id, 
       one_line, 
       sort_key, 
       email, 
       first_names || ' ' || last_name as name, 
       users.user_id as poster_id, 
       bboard_topics.presentation_type
from   bboard, users, bboard_topics
where  bboard.user_id = users.user_id 
and    bboard.topic_id = bboard_topics.topic_id
and    refers_to is null
and    bboard_topics.restricted_p = 'f' 
and    bboard_user_can_view_topic_p(:user_id, bboard.topic_id) = 't'
and    trunc(posting_time) = :kickoff_date
order by upper(bboard_topics.topic), sort_key" {

    if ![string equal $topic $last_topic] {
	set last_topic $topic
	append page_content "\n<h4>$topic</h4>\n"
    }
    append page_content "<li><a href=\"[bboard_msg_url $presentation_type $msg_id $topic]\">$one_line</a> ($name)\n"

} if_no_rows {
    append page_content "no new threads were started on $pretty_date"
}

append page_content "

</ul>

[bboard_footer]
"

doc_return  200 text/html $page_content