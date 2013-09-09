# /www/bboard/q-and-a-one-category.tcl
ad_page_contract {
    we're just looking at the uninteresting postings now

    @param topic the name of the bboard topic
    @param category a category within the topic

    @cvs-id q-and-a-one-category.tcl,v 3.1.2.5 2000/09/22 01:36:52 kevin Exp
} {
    topic_id:integer,notnull
    topic:optional
    {q_and_a_sort_order ""}
    category:notnull
}

# -----------------------------------------------------------------------------

# will set uplevel $topic if not passed to this page 
if  {[bboard_get_topic_info] == -1} {
    return
}

set page_content "
[bboard_header "$category threads in $topic"]

<h2>$category Threads</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list "q-and-a.tcl?topic=[ns_urlencode $topic]" $topic] "One Category"]


<hr>

<ul>
"

if { $category != "uncategorized" } {
    set category_clause "and category = :category"
} else {
    # **** NULL/'' problem, needs " or category = '' "
    set category_clause "and (category is NULL or category = 'Don''t Know')"
}


set uninteresting_header_written 0

db_foreach messages "
select urgent_p, 
       msg_id, 
       one_line, 
       sort_key, 
       posting_time, 
       email, 
       first_names || ' ' || last_name as name, 
       users.user_id as poster_id, 
       bboard_uninteresting_p(interest_level) as uninteresting_p
from   bboard, users
where  bboard.user_id = users.user_id
and    topic_id = :topic_id
and    refers_to is null
$category_clause
order by uninteresting_p, sort_key $q_and_a_sort_order" -column_set selection {

    set msg_id [ns_set iget $selection msg_id]
    set one_line [ns_set iget $selection one_line]
    set uninteresting_p [ns_set iget $selection uninteresting_p]

    if { $uninteresting_p == "t" && $uninteresting_header_written == 0 } {
	set uninteresting_header_written 1
	append page_content "
<h3>Uninteresting Threads</h3>

(or at least the forum moderator thought they would only be of interest to rare individuals; truly worthless threads get deleted altogether)

<p>

"
    }
    append page_content "<li><a target=\"_top\" href=\"[bboard_msg_url $presentation_type $msg_id $topic_id]\">$one_line</a> [bboard_one_line_suffix $selection $subject_line_suffix]\n"

}

# let's assume there was at least one posting

append page_content "
</ul>
[bboard_footer]
"



doc_return  200 text/html $page_content
