# /www/bboard/q-and-a-search-form.tcl
ad_page_contract {
    Form to allow users to enter a search query for the bboards

    @param topic_id the ID of the bboard topic
    @param topic the name of the bboard topic

    @cvs-id q-and-a-search-form.tcl,v 3.3.2.3 2000/09/22 01:36:53 kevin Exp
} {
    topic_id:integer,notnull
    topic:notnull
}

# -----------------------------------------------------------------------------

if {[bboard_get_topic_info] == -1} {
    return
}

set search_submit_button ""
if { [msie_p] == 1 } {
    set search_submit_button "<input type=submit value=\"Submit Query\">"
}

set search_server [ad_parameter BounceQueriesTo site-wide-search ""]

doc_return  200 text/html "[bboard_header "Search $topic Q&A"]\

<h2>Search</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Search"]

<hr>
<form method=GET action=\"$search_server/bboard/q-and-a-search\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
Full Text Search:  <input type=text name=query_string size=40>
$search_submit_button
</form>

[bboard_footer]"
