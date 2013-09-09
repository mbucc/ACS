# admin/neighbor/posting-delete.tcl
ad_page_contract {
    I don't think this ever gets used
    @cvs-id: posting-delete.tcl,v 3.2.2.4 2000/09/22 01:35:42 kevin Exp
    @author unknown
    @creation-date 2000-07-18
} {
    comment_id
}

# posting-delete.tcl,v 3.2.2.4 2000/09/22 01:35:42 kevin Exp
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


if {![db_0or1row neighbor_comment_select "
       select comment_id, content, general_comments.html_p as comment_html_p
         from general_comments
        where comment_id = :comment_id
"]} {
    ad_return_error "Can't find comment" "Can't find comment $comment_id"
    return
}

set doc_body "[ad_admin_header "Really delete comment" ]

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



doc_return  200 text/html $doc_body