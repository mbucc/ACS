# $Id: q-and-a-unanswered.tcl,v 3.0 2000/02/06 03:34:22 ron Exp $
# q-and-a-unanswered.tcl
#
# by philg@mit.edu in 1995
#
# returns a listing of the threads that haven't been answered,
# sorted by descending date

set_the_usual_form_variables

# topic (required)

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}


ReturnHeaders

ns_write "[bboard_header "$topic Unanswered Questions"]

<h2>Unanswered Questions</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Unanswered Questions"]

<hr>

<ul>
"

set rest_of_page ""

# we want only top level questions that have no answers

set sql "select urgent_p, msg_id, one_line, sort_key, posting_time, bbd1.user_id as poster_id, users.email,  users.first_names || ' ' || users.last_name as name
from bboard bbd1, users 
where bbd1.user_id = users.user_id
and topic_id = $topic_id
and 0 = (select count(*) from bboard bbd2 where bbd2.refers_to = bbd1.msg_id)
and refers_to is null
order by sort_key $q_and_a_sort_order"

set selection [ns_db select $db $sql]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append rest_of_page "<li><a href=\"[bboard_msg_url $presentation_type $msg_id $topic]\">$one_line</a> [bboard_one_line_suffix $selection $subject_line_suffix]\n"

}

append rest_of_page "

</ul>

[bboard_footer]
"

ns_db releasehandle $db

ns_write $rest_of_page
