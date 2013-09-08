# /admin/links/by-page.tcl

ad_page_contract {
    Show links by page

    @param show_page_title_p Whether or not to show page titles
    @param order_by What to order pages by

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id by-page.tcl,v 3.2.2.5 2000/09/22 01:35:29 kevin Exp
} {
    show_page_title_p:optional
    {order_by "n_links"}
}

if { $order_by == "n_links" } {
    set title "Related Links"
    set order_by "n_links desc, url_stub"
    if { [info exists show_page_title_p] && $show_page_title_p } {
	set options "<a href=\"by-page?[export_url_vars order_by]\">hide page title</a> | <a href=\"by-page?show_page_title_p=1&order_by=url_stub\">order by URL</a>"
    } else {
	set options "<a href=\"by-page?[export_url_vars order_by]&show_page_title_p=1\">show page title</a> | <a href=\"by-page?order_by=[ns_urlencode "url_stub"]&show_page_title_p=0\">order by URL</a>"
    }
} else {
    set title "Related Links"
    set order_by "url_stub"
    if { [info exists show_page_title_p] && $show_page_title_p } {
	set options "<a href=\"by-page?[export_url_vars order_by]&show_page_title_p=0\">hide page title</a> | <a href=\"by-page?show_page_title_p=1&order_by=[ns_urlencode n_links]\">order by number of links</a>"
    } else {
	set options "<a href=\"by-page?[export_url_vars order_by]&show_page_title_p=1\">show page title</a> | <a href=\"by-page?order_by=[ns_urlencode "n_links"]&show_page_title_p=0\">order by number of links</a>"
    }
}

set page_content "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "index" "Links"] "By Page"]

<hr>

$options

<ul>
"



set sql_qry "select static_pages.page_id, page_title, url_stub, count(user_id) as n_links
from static_pages, links
where static_pages.page_id = links.page_id
group by static_pages.page_id, page_title, url_stub
order by $order_by"

set items ""
db_foreach select_pages_and_links $sql_qry {

    if { [string length $page_title] == 0 } {
	set page_title "<i>$url_stub</i>"
    } 

    append items "<li><A HREF=\"one-page?page_id=$page_id\">$url_stub ($n_links)</a>\n"
    if { [info exists show_page_title_p] && $show_page_title_p && ![empty_string_p $page_title]} {
	append items "-- $page_title\n"
    }
}

db_release_unused_handles

append page_content "$items

</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_content
