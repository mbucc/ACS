# www/general-comments/admin/edit.tcl

ad_page_contract {
    edit comment page

    @author philg@mit.edu
    @author tarik@arsdigita.com
    @creation-date 01/06/99
    @cvs-id edit.tcl,v 3.3.6.5 2000/09/22 01:38:02 kevin Exp

    @param comment_id The comment to edit
    @param return_url The page to return after editing the comment

} {
    comment_id:integer
    {return_url "index.tcl"}
}

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_scope_error_check 

set admin_id [general_comments_admin_authorize $comment_id]

if { $admin_id == 0 } {
    # we don't know who this is administering, 
    # so we won't be able to audit properly
    ad_returnredirect "/register/"
    return
}

db_1row comment_get "
select comment_id, content, general_comments.html_p as comment_html_p, approved_p
from general_comments
where comment_id = :comment_id" -bind [ad_tcl_vars_to_ns_set comment_id]

set html "
[ad_scope_admin_header "Edit comment"]
[ad_scope_admin_page_title "Edit comment"]
[ad_scope_admin_context_bar [list "index.tcl" "General Comments"] "Edit"]
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
[export_form_vars comment_id return_url]
</form>
</blockquote>
[ad_scope_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
