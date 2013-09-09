# /www/admin/comments/comment-edit.tcl

ad_page_contract {
    return 1 if you want to send the  author email
if the author is not listed for a page, it is assumed 
to be the comments_system_owner
send_author_message_p 
return 1 if the author should recieve mail 
The author is assumed to be the comments_system_owner
if there is none listed
(this really should be handled with parameters.ini)

    @param page_id
    @param message
    @param comment_type
    @param comment_id
    @param rating
    @param html_p

    @cvs-id comment-edit.tcl,v 3.1.2.5 2000/09/22 01:34:31 kevin Exp
} {
    page_id:integer
    message
    comment_type
    comment_id:integer
    rating:optional
    html_p:optional
   
}



proc send_author_message_p { comment_type } {
    switch $comment_type {
	"unanswered_question" { return 1 }
	"alternative_perspective" { return 1 }
	"rating" { return 1 }
	 default  { return 0 }
    }
}


if [catch { db_dml update_comments "update  comments set  message = :message, rating=rating, posting_time = SYSDATE, html_p=html_p where comment_id = :comment_id"} errmsg] {


	# there was some other error with the comment update
	
	ad_return_complaint "Error in updating comment" "
There was an error in updating your comment in the database.
Here is what the database returned:
<p>
<pre>
$errmsg
</pre>

Don't quit your browser. The database may just be busy.
You might be able to resubmit your posting five or ten minutes from now."

}

# page information
# if there is no title, we use the url stub
# if there is no author, we use the system administrator

db_1row display_page "select nvl(page_title,url_stub) as page_title, url_stub,  nvl(email,'[ad_system_owner]') as author_email
from static_pages, users
where static_pages.original_author = users.user_id (+)
and page_id = :page_id"


doc_return  200 text/html "[ad_admin_header "Comment modified"]

<h2>Comment modified</h2>

<hr> 
Comment of  <a href=\"$url_stub\">$page_title</a> is modified.

[ad_admin_footer]"

