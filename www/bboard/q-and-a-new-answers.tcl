# $Id: q-and-a-new-answers.tcl,v 3.0 2000/02/06 03:34:13 ron Exp $
# q-and-a-new-answers.tcl
#
# by philg@mit.edu back in 1995
# 

# this will either display answers new since a last visit or 
# simply ones new within the last week (if there is no obvious last visit)

set_the_usual_form_variables

# topic (required)

set db [ns_db gethandle]

if {[bboard_get_topic_info] == -1} {
    return
}


set headers [ns_conn headers]
set cookie [ns_set get $headers Cookie]

set second_to_last_visit [ad_second_to_last_visit_ut]

if [empty_string_p $second_to_last_visit] {
    set title "postings in the last seven days"
    set explanation ""
    set query_time_limit "sysdate - 7"
} else {
    set title "postings since your last visit"
    set explanation "These are discussions in which there has been a contribution since your last visit, which we think was [ns_fmttime $second_to_last_visit "%x %X %Z"]"
    set query_time_limit "to_date('[ns_fmttime $second_to_last_visit "%Y-%m-%d %H:%M:%S"]','YYYY-MM-DD HH24:MI:SS')"
}


ReturnHeaders

ns_write "[bboard_header "$topic $title"]

<h2>$title</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "New Postings"]


<hr>

$explanation
<ul>
"

set rest_of_page ""

set sql "select bnah.root_msg_id,count(*) as n_new,max(bnah.posting_time) as max_posting_time, to_char(max(bnah.posting_time),'YYYY-MM-DD') as max_posting_date, bboard.one_line as subject_line
from bboard_new_answers_helper bnah, bboard
where bnah.posting_time >  $query_time_limit
and bnah.root_msg_id = bboard.msg_id
and bnah.topic_id = $topic_id
group by root_msg_id, bboard.one_line
order by max_posting_time desc"

set selection [ns_db select $db $sql]
set counter 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    if { $n_new == 1 } {
	set answer_phrase "answer, "
    } else {
	set answer_phrase "answers, last "
    }
    append rest_of_page "<li><a href=\"[bboard_msg_url $presentation_type $root_msg_id $topic]\">$subject_line</a> ($n_new new $answer_phrase on [util_AnsiDatetoPrettyDate $max_posting_date])"

}

if { $counter == 0 } {
    append rest_of_page "<p> ... it seems that there haven't been
any new responses."
}

append rest_of_page "

</ul>

[bboard_footer]
"

ns_db releasehandle $db

ns_write $rest_of_page
