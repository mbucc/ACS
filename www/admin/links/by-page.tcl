# $Id: by-page.tcl,v 3.0 2000/02/06 03:24:30 ron Exp $
set_the_usual_form_variables 0

# optional:  show_page_title_p, order_by 

if { ![info exists order_by] || $order_by == "n_links" } {
    set title "Related Links"
    set order_by "n_links desc, url_stub"
    if { [info exists show_page_title_p] && $show_page_title_p } {
	set options "<a href=\"by-page.tcl?[export_url_vars order_by]\">hide page title</a> | <a href=\"by-page.tcl?show_page_title_p=1&order_by=url_stub\">order by URL</a>"
    } else {
	set options "<a href=\"by-page.tcl?[export_url_vars order_by]&show_page_title_p=1\">show page title</a> | <a href=\"by-page.tcl?order_by=[ns_urlencode "url_stub"]&show_page_title_p=0\">order by URL</a>"
    }
} else {
    set title "Related Links"
    set order_by "url_stub"
    if { [info exists show_page_title_p] && $show_page_title_p } {
	set options "<a href=\"by-page.tcl?[export_url_vars order_by]&show_page_title_p=0\">hide page title</a> | <a href=\"by-page.tcl?show_page_title_p=1&order_by=[ns_urlencode n_links]\">order by number of links</a>"
    } else {
	set options "<a href=\"by-page.tcl?[export_url_vars order_by]&show_page_title_p=1\">show page title</a> | <a href=\"by-page.tcl?order_by=[ns_urlencode "n_links"]&show_page_title_p=0\">order by number of links</a>"
    }
}


ReturnHeaders

ns_write "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "By Page"]

<hr>

$options

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select static_pages.page_id, page_title, url_stub, count(user_id) as n_links
from static_pages, links
where static_pages.page_id = links.page_id
group by static_pages.page_id, page_title, url_stub
order by $order_by"]

set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    if { [string length $page_title] == 0 } {
	set page_title "<i>$url_stub</i>"
    } 

    append items "<li><A HREF=\"one-page.tcl?page_id=$page_id\">$url_stub ($n_links)</a>\n"
    if { [info exists show_page_title_p] && $show_page_title_p && ![empty_string_p $page_title]} {
	append items "-- $page_title\n"
    }
}

ns_write $items

ns_write "
</ul>

[ad_admin_footer]
"
