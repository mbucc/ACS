# /www/bboard/admin-q-and-a-search.tcl
ad_page_contract {
    Present the results of the search

    @param query_string the user provided search string
    @param topic the name of the bboard topic

    @cvs-id admin-q-and-a-search.tcl,v 3.2.2.5 2000/09/22 01:36:46 kevin Exp
} {
    query_string:notnull
    topic:notnull
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

append page_content "
[bboard_header "Search Results"]


<h2>Messages matching \"$query_string\"</h2>

in the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic</a> forum.

<hr>
\[ <a href=\"q-and-a-post-new?[export_url_vars topic topic_id]\">Ask New Question</a> \]

<ul>
"

set final_query_string [db_string query_string "select im_convert(:query_string) from dual"]

db_foreach search_results "
select msg_id, 
       sort_key, 
       one_line,  
       first_names || ' ' || last_name as name, 
       email
from   bboard, 
       users,
       site_wide_index sws
where  bboard.user_id = users.user_id
and    contains(sws.datastore, :final_query_string, 10) > 0
and    topic_id = :topic_id
order by score(10) desc" {

    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    append page_content "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg?msg_id=$thread_start_msg_id\">$one_line</a>
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"
} if_no_rows {
    append page_content "<li>No messages matched your search string."
}

append page_content "
</ul>

<form method=POST action=admin-q-and-a-search-pls target=\"_top\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
New Search:  <input type=text name=query_string size=40 value=\"$query_string\">
</form>

[bboard_footer]
"

doc_return  200 text/html $page_content