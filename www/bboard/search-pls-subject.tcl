# /www/bboard/search-pls-subject.tcl
ad_page_contract {
    show search results

    @cvs-id search-pls-subject.tcl,v 3.2.2.3 2000/09/22 01:36:54 kevin Exp
} {
    query_string:notnull
    topic
    topic_id:integer
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

# we ask for all the top level messages


append page_content "
[bboard_header "Search Results"]

<b>Messages matching \"$query_string\"</b>

<pre>
"
ad_context_query_string

db_foreach query_results "
select sort_key,
       msg_id,
       one_line
from   bboard
where  contains (indexed_stuff, '\$($query_string_for_ctx)', 10) > 0
and    topic_id = :topic_id
and    bboard_user_can_view_topic_p(:user_id, :topic_id) = 't'
order by score(10) desc" {

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

# let's cut the user free

doc_return  200 text/html $page_content

# but we keep the thread alive to log the query

ad_record_query_string $query_string "bboard-$topic" $counter $user_id

