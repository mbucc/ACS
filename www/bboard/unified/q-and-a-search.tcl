# /www/bboard/unified/q-and-a-search.tcl
ad_page_contract {
    Search page for unified bboards

    @param query_string string to search on

    @author LuisRodriguez@photo.net
    @cvs-id q-and-a-search.tcl,v 1.2.2.6 2000/09/22 01:37:00 kevin Exp
} {
    query_string:notnull,trim
}

# -----------------------------------------------------------------------------

ad_return_if_another_copy_is_running

set user_id [ad_maybe_redirect_for_registration]

# If we're doing the dual server thing and the user still got here somehow,
# bounce them over to the search server.
set search_server [ad_parameter BounceQueriesTo site-wide-search ""]
if { ![empty_string_p $search_server] } {
    ad_returnredirect "$search_server/bboard/q-and-a-search?[export_entire_form_as_url_vars]"
    return
}

set topics_in_user_default [db_string user_default_topics "
SELECT count(*)
FROM bboard_unified
WHERE user_id = :user_id"]

if { $user_id == 0 || $topics_in_user_default == 0 } {
    set topic_id_sql "SELECT topic_id
             FROM bboard_topics
             WHERE default_topic_p = 't'
            "
} else {
    set topic_id_sql "SELECT topic_id
             FROM bboard_unified
             WHERE default_topic_p = 't'
             AND   user_id = :user_id
    "
}

set topic_id_list [db_list user_topics $topic_id_sql]

set results_base_url [ad_parameter BounceResultsTo site-wide-search ""]

# we ask for all the top level messages

set final_query_string [db_string final_query "
select im_convert(:query_string) from dual"]

append search_res_items " <h3> Results from Search </h3>"

db_foreach serach_rows "
select /*+ FIRST_ROWS */ score(10) as the_score, 
       bboard.*, 
       users.first_names || ' ' || users.last_name as name, 
       users.email
from   bboard, users, site_wide_index sws
where  contains(sws.datastore, :final_query_string, 10) > 0
and    sws.table_name = 'bboard'
and    bboard.msg_id = sws.the_key
and    bboard.user_id = users.user_id
and    topic_id IN ($topic_id_sql)
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
    set display_string $one_line
    if { $subject_line_suffix == "name" } {
	append display_string "  ($name)"
    } elseif { $subject_line_suffix == "email" } {
	append display_string "  ($email)"
    }
    append search_res_items "<li>$the_score: <a href=\"$results_base_url/bboard/q-and-a-fetch-msg?msg_id=$thread_start_msg_id\">$display_string</a>\n"

} if_no_rows {
    append search_res_items "<li>sorry, but no messages matched this query; remember that your query string should be space-separated words without plurals (since we're just doing simple stupid keyword matching)\n"
}

foreach topic_id $topic_id_list {
    db_1row topic_name "
    SELECT topic 
    FROM bboard_topics
    WHERE topic_id=:topic_id
    "
    ad_record_query_string $query_string $topic $counter $user_id
}

append search_res_items "
</ul>
"

db_release_unused_handles

set page_content "

[bboard_header "Search Results"]

<h2>Messages matching \"$query_string\"</h2>

[ad_context_bar_ws_or_index [list "$results_base_url/bboard/index" [bboard_system_name]] [list "/bboard/unified" "Personalized Forum View"] "Search Results"]

<hr>

$search_res_items

<form method=GET action=q-and-a-search target=\"_top\">
[export_form_vars topic topic_id]
New Search:  <input type=text name=query_string size=40 value=\"[philg_quote_double_quotes $query_string]\">
</form>

[bboard_footer]
"

doc_return  200 text/html $page_content