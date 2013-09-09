# /www/admin/static/static-pages.tcl

ad_page_contract {
    @param order_by How to order the columns
    @param suppress_unindexed_p Don't show unindexed columns    
    @author mbryzek@arsdigita.com
    @creation-date Jul 7 2000

    @cvs-id static-pages.tcl,v 3.2.2.5 2000/09/22 01:36:09 kevin Exp
} {
    order_by:optional
    suppress_unindexed_p:optional
}

if { ![info exists order_by] || [empty_string_p $order_by] || $order_by == "url" } {
    set option "order by <a href=\"static-pages?order_by=title\">title</a>"
    set order_by_clause "url_stub, upper(rtrim(ltrim(page_title)))"
} elseif { $order_by == "title" } {
    set option "order by <a href=\"static-pages?order_by=url\">URL</a>"
    set order_by_clause "upper(rtrim(ltrim(page_title))), url_stub"
}

if { ![info exists suppress_unindexed_p] || !$suppress_unindexed_p } {
    set help_table [help_upper_right_menu [list "static-pages.tcl?suppress_unindexed_p=1&[export_url_vars order_by]" "suppress unindexed pages"]]
    set suppress_unindexed_p_clause ""
} else {
    # don't show pages that aren't indexed
    set help_table [help_upper_right_menu [list "static-pages.tcl?suppress_unindexed_p=0&[export_url_vars order_by]" "show unindexed pages"]]
    set suppress_unindexed_p_clause "\nand index_p <> 'f'"
}


set page_body "[ad_admin_header "Static Pages"]

<h2>Static Pages</h2>

[ad_admin_context_bar [list "index" "Static Content"] "All Pages"]

<hr>

$help_table

$option

<ul>
"

set sql_query "select page_id, rtrim(ltrim(page_title,' \n'),' \n') as page_title, url_stub
from static_pages
where draft_p <> 't' $suppress_unindexed_p_clause
order by :order_by_clause"

#:suppress_unindexed_p_clause

db_foreach static_pages_page_loop $sql_query {
    append page_body "<li><A HREF=\"page-summary?[export_url_vars page_id]\">$url_stub</a> ($page_title)\n"
}

append page_body "
</ul>
[ad_admin_footer]
"

doc_return  200 text/html $page_body
