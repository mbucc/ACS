# $Id: comment-edit.tcl,v 3.0 2000/02/06 03:14:53 ron Exp $
# return 1 if you want to send the  author email

# if the author is not listed for a page, it is assumed 
# to be the comments_system_owner

# send_author_message_p 
# return 1 if the author should recieve mail 
# The author is assumed to be the comments_system_owner
# if there is none listed
# (this really should be handled with parameters.ini)

proc send_author_message_p { comment_type } {
    switch $comment_type {
	"unanswered_question" { return 1 }
	"alternative_perspective" { return 1 }
	"rating" { return 1 }
	 default  { return 0 }
    }
}

set_the_usual_form_variables

# page_id, message, comment_type, comment_id
# maybe rating, maybe html_p


set db [ns_db gethandle]

if [catch { ns_ora clob_dml $db "update  comments set  message = empty_clob(), rating='[export_var rating]', posting_time = SYSDATE, html_p='[export_var html_p]' where comment_id = $comment_id  returning message into :1" "$message"} errmsg] {

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

set selection [ns_db 1row $db "select nvl(page_title,url_stub) as page_title, url_stub,  nvl(email,'[ad_system_owner]') as author_email
from static_pages, users
where static_pages.original_author = users.user_id (+)
and page_id = $page_id"]

set_variables_after_query

ns_return 200 text/html "[ad_admin_header "Comment modified"]

<h2>Comment modified</h2>

<hr> 
Comment of  <a href=\"$url_stub\">$page_title</a> is modified.

[ad_admin_footer]"



