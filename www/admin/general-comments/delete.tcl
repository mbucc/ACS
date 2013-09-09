# www/admin/general-comments/delete.tcl

ad_page_contract {
    Verifies if user would like to delete a comment.

    @cvs-id  delete.tcl,v 3.2.2.4 2000/09/22 01:35:24 kevin Exp
    @param comment_id The comment to delete

} {
    comment_id:integer
}


set comment_exists_p \
	[db_0or1row general_comments_properties \
	"select comment_id, content, general_comments.html_p as comment_html_p
         from general_comments
         where comment_id = :comment_id"]
if {!$comment_exists_p} {
    db_release_unused_handles
    ad_return_error "Can't find comment" "Can't find comment $comment_id"
    return
}

db_release_unused_handles
doc_return 200 text/html "[ad_admin_header "Really delete comment" ]

<h2>Really delete comment</h2>

<hr>

<form action=delete-2 method=post>
Do you really wish to delete the following comment?
<blockquote>
[util_maybe_convert_to_html $content $comment_html_p]
</blockquote>
<center>
<input type=submit name=submit value=\"Proceed\">
<input type=submit name=submit value=\"Cancel\">
</center>
[export_form_vars comment_id]
</form>
[ad_admin_footer]
"
