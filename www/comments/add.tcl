ad_page_contract {
    @param page_id
    @cvs-id add.tcl,v 3.2.2.5 2000/09/22 01:37:15 kevin Exp
} {
    {page_id:naturalnum,notnull}
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


# page information
# if there is no title, we use the url stub
# if there is no author, we use the system administrator

set selection [db_0or1row comments_add_page_data_get "
select  nvl(page_title,url_stub) as page_title, url_stub, nvl(email,'[ad_system_owner]') as email,
first_names || ' ' || last_name as name
from static_pages, users
where static_pages.original_author = users.user_id (+)
and page_id = :page_id"]

if {$selection == 0} {
    ad_return_complaint "Invalid page id" "Page id could not be found"
    db_release_unused_handles
    return
}
doc_return  200 text/html "[ad_header "Add a comment to $page_title" ]

<h2>Add a comment</h2>

to <a href=\"$url_stub\">$page_title</a>
<hr>
I just want to say whether I liked this page or not:
<a href=\"rating-add?page_id=$page_id\">Add a rating</a>.
<p>

I have an alternative perspective to contribute that
will be of interest to other readers of this page two or three years
from now:  <a href=\"persistent-add?page_id=$page_id\">Add a persistent comment</a>.

<p>

This page did not answer a question I expected it to answer: <a href=\"question-ask?page_id=$page_id\">Ask a question</a>.

<p>

I just want to send some email: <a
href=\"mailto:$email\">Send email to author or maintainer</a>.

[ad_footer]
"









