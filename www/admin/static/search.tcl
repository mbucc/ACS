# /www/admin/static/search.tcl

ad_page_contract {
    Search static pages

    @author mbryzek@arsdigita.com
    @creation-date Jul 8 2000

    @cvs-id search.tcl,v 3.3.2.5 2000/09/22 01:36:09 kevin Exp
} {
    query_string:notnull
    order_by:optional
}

if { ![info exists order_by] || [empty_string_p $order_by] || $order_by == "url" } {
    set option "order by <a href=\"search?query_string=$query_string&order_by=title\">title</a>"
    set order_by_clause "url_stub, upper(rtrim(ltrim(page_title)))"
} elseif { $order_by == "title" } {
    set option "order by <a href=\"search?query_string=$query_string&order_by=url\">URL</a>"
    set order_by_clause "upper(rtrim(ltrim(page_title))), url_stub"
}


set page_body "[ad_admin_header "Static Pages matching \"$query_string\""]

<h2>Static Pages matching \"$query_string\"</h2>

[ad_admin_context_bar [list "index" "Static Content"] "Search Results"]

<hr>

$option

<ul>
"


set sql_query "select page_id, rtrim(ltrim(page_title,' \n'),' \n') as page_title, url_stub
from static_pages
where draft_p <> 't' 
and (upper(page_title) like upper('%$query_string%')
     or upper(url_stub) like upper('%$query_string%'))
order by :order_by_clause"

db_foreach static_pages_get_pages_loop $sql_query {
    append page_body "<li><A HREF=\"page-summary?[export_url_vars page_id]\">$url_stub</a> ($page_title)\n"
}

append page_body "
</ul>
[ad_admin_footer]
"



doc_return  200 text/html $page_body
