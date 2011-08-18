# $Id: search-entire-system.tcl,v 3.1.4.1 2000/04/28 15:09:44 carsten Exp $
set_the_usual_form_variables
# query_string

if { ![info exists query_string] || $query_string == "" } {
    # probably using MSIE
    ns_return 200 text/html "[bboard_header "Missing Query"]

<h2>Missing Query</h2>

<hr>

Either you didn't type a query string or you're using a quality Web
browser like Microsoft Internet Explorer 3.x (which neglects to 
pass user input up the server).

[bboard_footer]
"
    return
}

# If we're doing the dual server thing and the user still got here somehow,
# bounce them over to the search server.
set search_server [ad_parameter BounceQueriesTo site-wide-search ""]
if { ![empty_string_p $search_server] } {
    ad_returnredirect "$search_server/bboard/search-entire-system.tcl?[export_entire_form_as_url_vars]"
    return
}
 


set db [ns_db gethandle]
if { $db == "" } {
    ad_return_error_page
    return
}


# we ask for all the top level messages

ReturnHeaders

ns_write "[bboard_header "Search Results"]

<h2>Messages matching \"$query_string\"</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] "Search Results"]

<hr>

<ul>

"

set final_query_string [database_to_tcl_string $db "select im_convert('[string trim $QQquery_string]') from dual"]

set user_id [ad_get_user_id]

if [catch {set selection [ns_db select $db "select /*+ FIRST_ROWS */ score(10) as the_score, msg_id, one_line, sort_key, bboard_topics.topic, bboard_topics.presentation_type
from bboard, bboard_topics, users, site_wide_index swi
where contains(swi.datastore, '$final_query_string', 10) > 0
and swi.table_name = 'bboard'
and bboard.msg_id = swi.the_key
and bboard.user_id = users.user_id
and bboard_topics.topic_id = bboard.topic_id 
and (bboard_topics.moderation_policy is null or bboard_topics.moderation_policy != 'private')
and (bboard_topics.group_id is null or bboard_topics.group_id in (select group_id from user_group_map where user_id=$user_id))
and (active_p = 't' or active_p is null)
order by 1 desc"]} errmsg] {
    
    ns_write "Ouch!  Our query made Oracle unhappy:
<pre>
$errmsg
</pre>
</ul>
    [bboard_footer]"
    
    return   
}

set counter 0

set results_base_url [ad_parameter BounceResultsTo site-wide-search ""]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    if { ![info exists max_score] } {
	# first iteration, this is the highest score
	set max_score $the_score
    }
    if { [ad_search_results_cutoff $counter $the_score $max_score] } {
	ns_db flush $db
	break
    }
    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }

    ns_write "<li>$the_score: <a href=\"$results_base_url/bboard/[bboard_msg_url $presentation_type $thread_start_msg_id $topic]\">$one_line</a>
(topic:  $topic)
"
}


ad_record_query_string $query_string $db "entire bboard" $counter $user_id

if { $counter == 0 } {
    ns_write "<li>sorry, but no messages matched this query; remember that your query string should be space-separated words without plurals (since we're just doing simple stupid keyword matching)\n"
} 

ns_write "
</ul>
[bboard_footer]
"
