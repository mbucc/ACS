ad_page_contract {
    @param comment_id
    @cvs-id one.tcl,v 3.2.2.5 2000/09/22 01:37:17 kevin Exp
} {
    {comment_id:naturalnum,notnull}
}


set selection [db_0or1row comment_get "
select nvl(page_title, 'untitled page') as page_title, p.page_id, message, first_names, last_name, 
       posting_time, c.user_id
from comments c, static_pages p, users u
where c.comment_id = :comment_id
and c.page_id = p.page_id
and c.user_id = u.user_id"]

if {$selection == 0} {
    ad_return_complaint "Invalid comment id" "Comment id oculd not be found."
    db_release_unused_handles
    return
}

doc_return  200 text/html "[ad_header "One Comment"]

<h2>One Comment</h2>

on <a href=\"/search/static-page-redirect?page_id=$page_id\">$page_title</a>

<hr>

<blockquote>
$message
</blockquote>

-- <a href=\"/shared/community-member?user_id=$user_id\">$first_names $last_name</a> ($posting_time)

[ad_footer]
"
