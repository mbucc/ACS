# www/comments/index.tcl

ad_page_contract {
    @cvs-id index.tcl,v 3.1.6.3 2000/09/22 01:37:17 kevin Exp
} {
    {show_page_title_p 0}
}

set title "Comments by page"
set and_clause ""
set order_by "n_comments desc"

if { $show_page_title_p } {
    set options "<a href=\"index?only_unanswered_questions_p=0&show_page_title=0\">hide page title</a>"
} else {
    set options "<a href=\"index?only_unanswered_questions_p=0&show_page_title_p=1\">show page title</a>"
}

set html "[ad_header $title]

<h2>$title</h2>
in [ad_site_home_link]
<hr>
$options
<ul>
"

set sql "select static_pages.page_id, page_title, url_stub, count(user_id) as n_comments
from static_pages, comments_not_deleted comments
where static_pages.page_id = comments.page_id 
and comment_type = 'alternative_perspective'
group by static_pages.page_id, page_title, url_stub
order by $order_by"

set items ""
db_foreach comment_list $sql {
    append items "<li><A HREF=\"for-one-page?page_id=$page_id\">$url_stub ($n_comments)</a>\n"
    if { [info exists show_page_title_p] && $show_page_title_p && ![empty_string_p $page_title]} {
	append items "-- $page_title\n"
    }
}

append html "
$items
</ul>
[ad_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
