# $Id: q-and-a-one-category.tcl,v 3.0.4.1 2000/05/11 13:09:17 carsten Exp $
set_the_usual_form_variables

# topic, category required

# we're just looking at the uninteresting postings now

set db [ns_db gethandle]
 
if  {[bboard_get_topic_info] == -1} {
    return}

set moby_string "[bboard_header "$category threads in $topic"]

<h2>$category Threads</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list "q-and-a.tcl?topic=[ns_urlencode $topic]" $topic] "One Category"]


<hr>

<ul>
"

if { $category != "uncategorized" } {
    set category_clause "and category = '$QQcategory'"
} else {
    # **** NULL/'' problem, needs " or category = '' "
    set category_clause "and (category is NULL or category = 'Don''t Know')"
}



set sql "select urgent_p, msg_id, one_line, sort_key, posting_time, email, first_names || ' ' || last_name as name, users.user_id as poster_id, bboard_uninteresting_p(interest_level) as uninteresting_p
from bboard, users
where bboard.user_id = users.user_id
and topic_id = $topic_id
and refers_to is null
$category_clause
order by uninteresting_p, sort_key $q_and_a_sort_order"

set selection [ns_db select $db $sql]

set uninteresting_header_written 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    if { $uninteresting_p == "t" && $uninteresting_header_written == 0 } {
	set uninteresting_header_written 1
	append moby_string "
<h3>Uninteresting Threads</h3>

(or at least the forum moderator thought they would only be of interest to rare individuals; truly worthless threads get deleted altogether)

<p>

"
    }
    append moby_string "<li><a target=\"_top\" href=\"[bboard_msg_url $presentation_type $msg_id $topic_id $topic]\">$one_line</a> [bboard_one_line_suffix $selection $subject_line_suffix]\n"

}

# let's assume there was at least one posting

append moby_string "
</ul>
[bboard_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $moby_string
