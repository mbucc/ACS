# $Id: index.tcl,v 3.0.4.1 2000/04/28 15:11:27 carsten Exp $
# search.tcl
# 
# the main public search form
# 
# 

set search_server [ad_parameter BounceQueriesTo site-wide-search ""]

if { ![empty_string_p $search_server] } {
    ad_returnredirect "$search_server/search/"
    return
}

set db [ns_db gethandle]

ns_return 200 text/html "[ad_header "Search [ad_system_name]"]

<h2>Search</h2>

[ad_context_bar_ws_or_index "Search"]

<hr>

<a href=\"/photo/pcd1253/outside-hearst-56.tcl\"><img hspace=5 vspace=5 align=right HEIGHT=198 WIDTH=132 src=\"/photo/pcd1253/outside-hearst-56.1.jpg\" ALT=\"Manhattan 1995.\"></a>

<form action=search.tcl method=GET>
[ad_site_wide_search_widget $db]
</form>

<br clear=right>

[ad_footer]
"
