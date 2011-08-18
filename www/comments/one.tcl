# $Id: one.tcl,v 3.0 2000/02/06 03:37:18 ron Exp $
set_form_variables
# comment_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select nvl(page_title, 'untitled page') as page_title, p.page_id, message, first_names, last_name, posting_time, c.user_id
from comments c, static_pages p, users u
where c.comment_id = $comment_id
and c.page_id = p.page_id
and c.user_id = u.user_id"]

set_variables_after_query

ns_return 200 text/html "[ad_header "One Comment"]

<h2>One Comment</h2>

on <a href=\"/search/static-page-redirect.tcl?page_id=$page_id\">$page_title</a>

<hr>

<blockquote>
$message
</blockquote>

-- <a href=\"/shared/community-member.tcl?user_id=$user_id\">$first_names $last_name</a> ($posting_time)

[ad_footer]
"
