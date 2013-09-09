# /www/bboard/search-subject.tcl
ad_page_contract {
    
    @cvs-id search-subject.tcl,v 3.2.2.3 2000/09/22 01:36:55 kevin Exp
} {
    query_string:notnull
    topic
    topic_id:integer
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

if {[bboard_get_topic_info] == -1} {
    return
}

# we ask for all the top level messages


append page_content "
[bboard_header "Search Results"]

<b>Messages matching \"$query_string\"</b>

<pre>
"

regsub -all {,+} [string trim query_string] " " final_query_string

db_foreach serach_results "
select /*+ INDEX(bboard bboard_for_one_category) */ bboard_contains(email, first_names || last_name, one_line, message,:final_query_string) as the_score, 
       sort_key,
       msg_id,
       one_line
from   bboard, 
       users
where  bboard_contains(email, first_names || last_name, one_line, message,:final_query_string) > 0
and bboard.user_id = users.user_id
and topic_id = :topic_id
and bboard_user_can_view_topic_p(:user_id, :topic_id) = 't'
order by 1 desc" {

    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    append page_content "<a target=main href=\"fetch-msg?msg_id=$msg_id\">$one_line</a> <a target=\"_top\" href=\"main-frame?[export_url_vars topic topic_id]&feature_msg_id=$msg_id&start_msg_id=$thread_start_msg_id\">(view entire thread)</a>\n"
}

append page_content "
</pre>
[bboard_footer]
"

doc_return  200 text/html $page_content