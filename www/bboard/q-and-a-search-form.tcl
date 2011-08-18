# $Id: q-and-a-search-form.tcl,v 3.1 2000/02/23 01:49:39 bdolicki Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic_id, topic required

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if {[bboard_get_topic_info] == -1} {
    return
}


set search_submit_button ""
if { [msie_p] == 1 } {
    set search_submit_button "<input type=submit value=\"Submit Query\">"
}

set_variables_after_query

set search_server [ad_parameter BounceQueriesTo site-wide-search ""]


ns_return 200 text/html "[bboard_header "Search $topic Q&A"]\

<h2>Search</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Search"]

<hr>
<form method=GET action=\"$search_server/bboard/q-and-a-search.tcl\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
Full Text Search:  <input type=text name=query_string size=40>
$search_submit_button
</form>

[bboard_footer]"
