# www/admin/general-comments/edit.tcl

ad_page_contract {
    Allows admin to edit a page
    @cvs-id edit.tcl,v 3.4.2.6 2000/09/22 01:35:24 kevin Exp
    @param comment_id The comment to edit
} {
    comment_id:integer
}


set user_id [ad_verify_and_get_user_id] 
ad_maybe_redirect_for_registration

set comment_exists_p \
	[db_0or1row general_comment_properties \
	"select comment_id, content, general_comments.html_p as comment_html_p, 
         approved_p
         from general_comments
         where comment_id = :comment_id"]

if {$comment_exists_p == 0} {
   ad_return_error "Can't find comment" "Can't find comment $comment_id"
    db_release_unused_handles
   return
}

doc_return  200 text/html "[ad_admin_header "Edit comment" ]

<h2>Edit comment </h2>

[ad_admin_context_bar [list "index.tcl" "General Comments"] "Edit"]

<hr>

<blockquote>
<form action=edit-2 method=post>
<textarea name=content cols=80 rows=20 wrap=soft>[philg_quote_double_quotes $content]</textarea><br>
Text above is
<select name=html_p>
 [ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $comment_html_p]
</select>
<br>
Approval status
<select name=approved_p>
 [ad_generic_optionlist {"Approved" "Unapproved"} {"t" "f"} $approved_p]
</select>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars comment_id]
</form>
</blockquote>
[ad_admin_footer]
"

