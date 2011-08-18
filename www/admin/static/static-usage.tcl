# $Id: static-usage.tcl,v 3.0 2000/02/06 03:30:31 ron Exp $
#
# /admin/static/static-usage.tcl
# 
# by philg@mit.edu in late 1998?
#
# summarize page views by registered users
#
# (modified November 6, 1999 to be able to sort by number of views)
#

set_the_usual_form_variables 0

# order_by (optional)

if { ![info exists order_by] || $order_by == "url" } {
    set help_table [help_upper_right_menu [list "static-usage.tcl?order_by=page_views" "order by page views"]]
    set order_by_clause "url_stub, upper(page_title)"
} else {
    set help_table [help_upper_right_menu [list "static-usage.tcl?order_by=url" "order by url"]]
    set order_by_clause "page_views desc, url_stub, upper(page_title)"
}

ReturnHeaders

ns_write "[ad_admin_header "Static Pages"]

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

set db [ns_db gethandle]

set selection [ns_db select $db "select static_pages.page_id, url_stub, page_title, count(user_id) as page_views
from static_pages, user_content_map
where static_pages.page_id = user_content_map.page_id
group by static_pages.page_id, url_stub, page_title
order by $order_by_clause"]

set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append items "<li><A HREF=\"$url_stub\">$url_stub</a> - <A HREF=\"page-summary.tcl?page_id=$page_id\">$page_views</a>\n"
}

ns_write $items

ns_write "
</ul>

[ad_admin_footer]
"
