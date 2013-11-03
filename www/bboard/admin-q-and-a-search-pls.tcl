# /www/bboard/admin-q-and-a-search-pls.tcl
ad_page_contract {
    Search using PLS

    @param query_string the search string provided by the user
    @param topic the name of the bboard topic

    @cvs-id admin-q-and-a-search-pls.tcl,v 3.2.2.3 2000/09/22 01:36:45 kevin Exp
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

append page_content [ad_header "" "Search Results"]

<h2>Messages matching \"$query_string\"</h2>

in the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic</a> forum.

<hr>
\[ <a href=\"q-and-a-post-new?[export_url_vars topic topic_id]\">Ask New Question</a> \]

<ul>
"

regsub -all { +} $query_string "," query_string_for_ctx
regsub -all {,+} $query_string_for_ctx "," query_string_for_ctx
set query_string_for_ctx "\$($query_string_for_ctx)"

db_foreach search_results "
select msg_id, 
       sort_key, 
       one_line,  
       first_names || ' ' || last_name as name, 
       email
from   bboard, 
       users
where  bboard.user_id = users.user_id
and    contains (indexed_stuff, :query_string_for_ctx, 10) > 0
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



doc_return  200 text/htmll $page_content
