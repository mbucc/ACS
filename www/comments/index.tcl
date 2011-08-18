# $Id: index.tcl,v 3.0 2000/02/06 03:37:17 ron Exp $
set_the_usual_form_variables 0

# optional:  show_page_title_p

set title "Comments by page"
set and_clause ""
set order_by "n_comments desc"
if { [info exists show_page_title_p] && $show_page_title_p } {
	set options "<a href=\"index.tcl?only_unanswered_questions_p=0&show_page_title=0\">hide page title</a>"
} else {
	set options "<a href=\"index.tcl?only_unanswered_questions_p=0&show_page_title_p=1\">show page title</a>"
}

ReturnHeaders

ns_write "[ad_header $title]

<h2>$title</h2>

in [ad_site_home_link]

<hr>

$options

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select static_pages.page_id, page_title, url_stub, count(user_id) as n_comments
from static_pages, comments_not_deleted comments
where static_pages.page_id = comments.page_id 
and comment_type = 'alternative_perspective'
group by static_pages.page_id, page_title, url_stub
order by $order_by"]

set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    append items "<li><A HREF=\"for-one-page.tcl?page_id=$page_id\">$url_stub ($n_comments)</a>\n"
    if { [info exists show_page_title_p] && $show_page_title_p && ![empty_string_p $page_title]} {
	append items "-- $page_title\n"
    }
}

ns_write $items

ns_write "
</ul>

[ad_footer]
"
