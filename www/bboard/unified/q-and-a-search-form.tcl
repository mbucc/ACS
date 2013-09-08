# /www/bboard/unified/q-and-a-search-form.tcl
ad_page_contract {
    Form to search personalized forums

    @author LuisRodriguez@photo.net
    @creation-date May 2000
    @cvs-id q-and-a-search-form.tcl,v 1.2.2.3 2000/09/22 01:37:00 kevin Exp
} {
}

# -----------------------------------------------------------------------------

set search_submit_button ""
if { [msie_p] == 1 } {
    set search_submit_button "<input type=submit value=\"Submit Query\">"
}

set search_server [ad_parameter BounceQueriesTo site-wide-search ""]

doc_return  200 text/html "[bboard_header "Search Personalized Q&A Forums"]

<h2>Search</h2>

[ad_context_bar_ws_or_index [list "index" [bboard_system_name]] [list "/bboard/unified/display-view" "Personalized Forum View"] "Search"]

<hr>
<form method=GET action=\"$search_server/bboard/unified/q-and-a-search\">
Full Text Search:  <input type=text name=query_string size=40>
$search_submit_button
</form>

[bboard_footer]"
