# $Id: persistent-edit.tcl,v 3.0 2000/02/06 03:37:22 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables
# comment_id

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select comments.comment_id, comments.page_id, comments.message, static_pages.url_stub, nvl(page_title,  url_stub) as page_title, html_p, user_id as comment_user_id
from comments, static_pages
where comments.page_id = static_pages.page_id 
and comment_id = $comment_id"]

if [empty_string_p $selection] {
    ad_return_error "No comment found"  "Comment $comment_id is not in the database.  Perhaps it was already deleted." 
    return
} else {
    set_variables_after_query
    ns_db releasehandle $db
}

set user_id [ad_verify_and_get_user_id]

if { $comment_user_id != $user_id } {
    ad_return_error "Unauthorized" "You are not allowed to edit a comment you did not enter"
    return
}


ns_return 200 text/html "[ad_header "Edit comment on $page_title" ]

<h2>Edit comment</h2>

on <a href=\"$url_stub\">$page_title</a>
<hr>

<form action=persistent-edit-2.tcl method=post>
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
