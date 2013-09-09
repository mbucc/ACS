# /www/bboard/search-entire-system.tcl

ad_page_contract {
    Search all forum in bboard
    @param query_string Keyword to search
    @author unknown
    @creation-date unknown
    @cvs-id search-entire-system.tcl,v 3.3.2.6 2000/09/22 01:36:54 kevin Exp
} {
    query_string:trim,notnull
} 

# If we're doing the dual server thing and the user still got here somehow,
# bounce them over to the search server.
set search_server [ad_parameter BounceQueriesTo site-wide-search ""]
if { ![empty_string_p $search_server] } {
    ad_returnredirect "$search_server/bboard/search-entire-system.tcl?[export_url_vars query_string]"
    return
}
 
# we ask for all the top level messages

# Put the sql_query in a string so we can display it to the user if
# there is an error
set sql_query "select im_convert(:query_string) from dual"

if { [catch {set final_query_string [db_string query $sql_query]} err_msg] } {
    # This probably means im_convert is not loaded yet.
    ad_return_error "Error setting query string" "We got the following error while trying to execute 
<pre>$sql_query</pre>
<pre>$err_msg</pre>
<p>
This probably means the site-wide search module is not fully installed (i.e. the im_convert function has not been loaded).
"
    return 
}
set page_content "[bboard_header "Search Results"]

<h2>Messages matching \"$query_string\"</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] "Search Results"]

<hr>

<ul>

"

set user_id [ad_get_user_id]

set results_base_url [ad_parameter BounceResultsTo site-wide-search ""]

if [catch {
db_foreach result "select /*+ FIRST_ROWS */ score(10) as the_score,                                       msg_id, 
                           one_line, 
                           sort_key, 
                           bboard_topics.topic_id,
                           bboard_topics.topic, 
                           bboard_topics.presentation_type
                   from   bboard,
                          bboard_topics, 
                          users, 
                          site_wide_index swi
                   where contains(swi.datastore, :final_query_string, 10) > 0
                   and   swi.table_name = 'bboard'
                   and   bboard.msg_id = swi.the_key
                   and   bboard.user_id = users.user_id
                   and   bboard_topics.topic_id = bboard.topic_id 
                   and (bboard_topics.moderation_policy is null or bboard_topics.moderation_policy != 'private')
                   and (bboard_topics.group_id is null or bboard_topics.group_id in (select group_id from user_group_map where user_id = :user_id))
                   and (active_p = 't' or active_p is null)
                   order by 1 desc" {
 
    if { ![info exists max_score] } {
	# first iteration, this is the highest score
	set max_score $the_score
    }
    if { [ad_search_results_cutoff $counter $the_score $max_score] } {
	break
    }
    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }

    append page_content "<li>$the_score: <a href=\"$results_base_url/bboard/[bboard_msg_url $presentation_type $thread_start_msg_id $topic_id]\">$one_line</a>
(topic:  $topic)
"
} if_no_rows {
    append page_content "sorry, but no messages matched this query; remember that your query string should be space-separated words without plurals (since we're just doing simple stupid keyword matching)\n"
}
}] {
    ad_return_complaint 1 "Our search engine didn't like your query.  Please try just a set of space-seperated words."
    return
}

#ad_record_query_string $query_string "entire bboard" $counter $user_id
 
append page_content "
</ul>
[bboard_footer]
"

doc_return 200 text/html $page_content







