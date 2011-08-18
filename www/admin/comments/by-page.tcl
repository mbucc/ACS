# $Id: by-page.tcl,v 3.0 2000/02/06 03:14:51 ron Exp $
set_the_usual_form_variables 0

# optional:  show_page_title_p, only_unanswered_questions_p

if { [info exists only_unanswered_questions_p] && $only_unanswered_questions_p } {
    set title "Pages raising questions"
    set and_clause "\nand comment_type = 'unanswered_question'"
    set order_by "n_comments desc, url_stub"
    set link_suffix "#unanswered_question"
    if { [info exists show_page_title_p] && $show_page_title_p } {
	set options "<a href=\"by-page.tcl?only_unanswered_questions_p=1\">hide page title</a> | <a href=\"by-page.tcl?show_page_title_p=1\">all types of comments</a>"
    } else {
	set options "<a href=\"by-page.tcl?only_unanswered_questions_p=1&show_page_title_p=1\">show page title</a> | <a href=\"by-page.tcl?show_page_title_p=0\">all types of comments</a>"
    }
} else {
    set title "Comments by page"
    set and_clause ""
    set order_by "url_stub"
    set link_suffix ""
    if { [info exists show_page_title_p] && $show_page_title_p } {
	set options "<a href=\"by-page.tcl?only_unanswered_questions_p=0&show_page_title=0\">hide page title</a> | <a href=\"by-page.tcl?only_unanswered_questions_p=1&show_page_title_p=1\">just unanswered questions</a>"
    } else {
	set options "<a href=\"by-page.tcl?only_unanswered_questions_p=0&show_page_title_p=1\">show page title</a> | <a href=\"by-page.tcl?only_unanswered_questions_p=1&show_page_title_p=0\">just unanswered questions</a>"
    }
}

ReturnHeaders

ns_write "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Comments"] "By Page"]

<hr>

$options

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select static_pages.page_id, page_title, url_stub, count(user_id) as n_comments
from static_pages, comments_not_deleted comments
where static_pages.page_id = comments.page_id $and_clause
group by static_pages.page_id, page_title, url_stub
order by $order_by"]

set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    append items "<li><A HREF=\"/admin/static/page-summary.tcl?page_id=$page_id$link_suffix\">$url_stub ($n_comments)</a>\n"
    if { [info exists show_page_title_p] && $show_page_title_p && ![empty_string_p $page_title]} {
	append items "-- $page_title\n"
    }
}

ns_write $items

ns_write "
</ul>

[ad_admin_footer]
"
