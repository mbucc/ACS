ad_page_contract {
    @cvs-id static-usage.tcl,v 3.1.6.7 2000/09/22 01:36:09 kevin Exp
    @author philg@mit.edu 
    @creation-date late 1998?
    @param order_by optional

    /admin/static/static-usage.tcl
        
    summarize page views by registered users
    
    (modified November 6, 1999 to be able to sort by number of views)
} {
    order_by:optional
}

if { ![info exists order_by] || $order_by == "url" } {
    set help_table [help_upper_right_menu [list "static-usage.tcl?order_by=page_views" "order by page views"]]
    set order_by_clause "url_stub, upper(page_title)"
} else {
    set help_table [help_upper_right_menu [list "static-usage.tcl?order_by=url" "order by url"]]
    set order_by_clause "page_views desc, url_stub, upper(page_title)"
}

set page_content "[ad_admin_header "Static Pages"]

<h2>Static Usage</h2>

[ad_admin_context_bar [list "index.tcl" "Static Content"] "Usage"]

<hr>

$help_table

This is a listing of the number of users who
have viewed each page when they were logged into
the site.  Duplicate page views by the same user
are not counted.

<ul>
"



set items ""

db_foreach static_usage_select_page_data "select static_pages.page_id, 
url_stub, page_title, count(user_id) as page_views
from static_pages, user_content_map
where static_pages.page_id = user_content_map.page_id
group by static_pages.page_id, url_stub, page_title
order by $order_by_clause" {
    append items "<li><A HREF=\"$url_stub\">$url_stub</a> - <A HREF=\"page-summary?page_id=$page_id\">$page_views</a>\n"
}

append page_content " $items
</ul>

[ad_admin_footer]
"



doc_return  200 text/html $page_content