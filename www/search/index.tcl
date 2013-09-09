# /www/search/index.tcl

ad_page_contract {
    the main public search form

    @author phong@arsdigita.com
    @creation-date 2000-08-01
    @cvs-id index.tcl,v 3.4.6.6 2000/09/22 01:39:17 kevin Exp
} 

# check to see if another search server should handle searching
set search_server [ad_parameter BounceQueriesTo site-wide-search ""]
if { ![empty_string_p $search_server] } {
    ad_returnredirect "$search_server/search/"
    return
}

set page_content  "
[ad_header "Search [ad_system_name]"]
<h2>Search</h2>
[ad_context_bar_ws_or_index "Search"]
<hr>

Search [ad_system_name]<br>
[ad_site_wide_search_widget ""]

<a href=\"advanced-search\">Advanced search</a>
[ad_footer]
"

doc_return  200 text/html $page_content






