# $Id: add.tcl,v 3.0 2000/02/06 03:37:09 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables
# page_id

set db [ns_db gethandle]

# page information
# if there is no title, we use the url stub
# if there is no author, we usre the system administrator

set selection [ns_db 1row $db "select  nvl(page_title,url_stub) as page_title, url_stub, nvl(email,'[ad_system_owner]') as email,
first_names || ' ' || last_name as name
from static_pages, users
where static_pages.original_author = users.user_id (+)
and page_id = $page_id"]
set_variables_after_query
ns_db releasehandle $db

ns_return 200 text/html "[ad_header "Add a comment to $page_title" ]

<h2>Add a comment</h2>

to <a href=\"$url_stub\">$page_title</a>
<hr>
I just want to say whether I liked this page or not:
<a href=\"rating-add.tcl?page_id=$page_id\">Add a rating</a>.
<p>

I have an alternative perspective to contribute that
will be of interest to other readers of this page two or three years
from now:  <a href=\"persistent-add.tcl?page_id=$page_id\">Add a persistent comment</a>.

<p>

This page did not answer a question I expected it to answer: <a href=\"question-ask.tcl?page_id=$page_id\">Ask a question</a>.

<p>

I just want to send some email: <a
href=\"mailto:$email\">Send email to author or maintainer</a>.

[ad_footer]
"


