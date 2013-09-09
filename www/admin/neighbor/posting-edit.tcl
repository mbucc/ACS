#admin/neighbor/posting-edit.tcl
ad_page_contract {
    I can't find anywhere that links here
    @cvs_id posting-edit.tcl,v 3.2.2.4 2000/09/22 01:35:42 kevin Exp
    @author unknown

} {
    comment_id
}


# posting-edit.tcl,v 3.2.2.4 2000/09/22 01:35:42 kevin Exp
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}



if {![db_0or1row "neighbor_comments_select" "select comment_id, content, general_comments.html_p as comment_html_p, approved_p
from general_comments
where comment_id = :comment_id"]} {
    ad_return_error "Can't find comment" "Can't find comment $comment_id"
    return
}

set doc_body "[ad_admin_header "Edit comment" ]

<h2>Edit comment </h2>

<hr>

<blockquote>
<form action=edit-2 method=post>
<textarea name=content cols=50 rows=5 wrap=soft>[philg_quote_double_quotes $content]</textarea><br>
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



doc_return  200 text/html doc_body




