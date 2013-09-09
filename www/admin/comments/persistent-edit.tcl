# /www/admin/comments/persistent-edit.tcl

ad_page_contract {
    
    persistent-edit

    @param comment_id

    @cvs-id persistent-edit.tcl,v 3.1.6.4 2000/09/22 01:34:32 kevin Exp
} {
    comment_id:integer
}

if {[ad_administrator_p [ad_maybe_redirect_for_registration]] == 0} {
    ad_return_complaint 1 "You are not an administrator"
}

db_1row comment_display  "select comments.comment_id, comments.page_id, comments.message, static_pages.url_stub, nvl(page_title,  url_stub) as page_title, html_p
from comments, static_pages
where comments.page_id = static_pages.page_id 
and comment_id = :comment_id"



doc_return  200 text/html "[ad_admin_header "Edit comment on $page_title" ]

<h2>Edit comment</h2>

on <a href=\"$url_stub\">$page_title</a>
<hr>

<form action=persistent-edit-2 method=post>
[export_form_vars page_id comment_id]
<input type=hidden name=comment_type value=alternative_perspective>
Edit your comment or alternative perspective.<br>
<textarea name=message cols=80 rows=10 wrap=soft>[philg_quote_double_quotes $message]</textarea><br>
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
[ad_admin_footer]
"
