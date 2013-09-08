ad_page_contract {
    @param comment_id
    @cvs-id persistent-edit.tcl,v 3.1.6.5 2000/09/22 01:37:17 kevin Exp
} {
    {comment_id:naturalnum,notnull}
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set num_rows [db_0or1row comment_get "select comments.comment_id, comments.page_id, comments.message, static_pages.url_stub, nvl(page_title,  url_stub) as page_title, html_p, user_id as comment_user_id
from comments, static_pages
where comments.page_id = static_pages.page_id 
and comment_id = :comment_id" ]

if { $num_rows==0 } {
    ad_return_error "No comment found"  "Comment $comment_id is not in the database.  Perhaps it was already deleted." 
    return
} 

set user_id [ad_verify_and_get_user_id]

if { $comment_user_id != $user_id } {
    ad_return_error "Unauthorized" "You are not allowed to edit a comment you did not enter"
    return
}

doc_return  200 text/html "[ad_header "Edit comment on $page_title" ]

<h2>Edit comment</h2>

on <a href=\"$url_stub\">$page_title</a>
<hr>

<form action=persistent-edit-2 method=post>
[export_form_vars page_id comment_id]
<input type=hidden name=comment_type value=alternative_perspective>
Edit your comment or alternative perspective.<br>
<textarea name=message cols=50 rows=5 wrap=soft>[philg_quote_double_quotes $message]</textarea><br>
<br>
Text above is
<select name=html_p>
[ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $html_p]
</select>
<p>
<center>
<input type=submit name=submit value=\"Submit Changes\">
<input type=submit name=submit value=\"Delete Comment\">
</center>
</form>
[ad_footer]
"










