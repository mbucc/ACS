# $Id: q-and-a-search.tcl,v 3.1.4.1 2000/04/28 15:09:43 carsten Exp $
ad_return_if_another_copy_is_running

set_the_usual_form_variables

# query_string, topic, topic_id

# If we're doing the dual server thing and the user still got here somehow,
# bounce them over to the search server.
set search_server [ad_parameter BounceQueriesTo site-wide-search ""]
if { ![empty_string_p $search_server] } {
    ad_returnredirect "$search_server/bboard/q-and-a-search.tcl?[export_entire_form_as_url_vars]"
    return
}
 

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

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}


set results_base_url [ad_parameter BounceResultsTo site-wide-search ""]

# we ask for all the top level messages

ReturnHeaders

ns_write "[bboard_header "Search Results"]

<h2>Messages matching \"$query_string\"</h2>

[ad_context_bar_ws_or_index [list "$results_base_url/bboard/index.tcl" [bboard_system_name]] [list "$results_base_url/bboard/[bboard_raw_backlink $topic_id $topic $presentation_type 0]" $topic] "Search Results"]

<hr>

<ul>
"

set final_query_string [DoubleApos [database_to_tcl_string $db "select im_convert('[string trim $QQquery_string]') from dual"]]

with_catch errmsg {
    set selection [ns_db select $db "select /*+ FIRST_ROWS */ score(10) as the_score, bboard.*, users.first_names || ' ' || users.last_name as name, users.email
from bboard, users, site_wide_index sws
where contains(sws.datastore, '$final_query_string', 10) > 0
and sws.table_name = 'bboard'
and bboard.msg_id = sws.the_key
and bboard.user_id = users.user_id
and topic_id = $topic_id
order by 1 desc"]
} {
    ns_write "Ouch!  Our query made Oracle unhappy:
<pre>
$errmsg
</pre>
</ul>
[bboard_footer]"
    return
}

set counter 0 

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
    set display_string $one_line
    if { $subject_line_suffix == "name" } {
	append display_string "  ($name)"
    } elseif { $subject_line_suffix == "email" } {
	append display_string "  ($email)"
    }
    ns_write "<li>$the_score: <a href=\"$results_base_url/bboard/q-and-a-fetch-msg.tcl?msg_id=$thread_start_msg_id\">$display_string</a>\n"
}


set user_id [ad_get_user_id]
ad_record_query_string $query_string $db $topic $counter $user_id


if { $counter == 0 } {
    ns_write "<li>sorry, but no messages matched this query; remember that your query string should be space-separated words without plurals (since we're just doing simple stupid keyword matching)\n"
}

ns_write "
</ul>

<form method=GET action=q-and-a-search.tcl target=\"_top\">
[export_form_vars topic topic_id]
New Search:  <input type=text name=query_string size=40 value=\"[philg_quote_double_quotes $query_string]\">
</form>

[bboard_footer]
"

