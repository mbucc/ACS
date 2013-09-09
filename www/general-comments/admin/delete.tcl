# www/general-comments/admin/delete.tcl

ad_page_contract {
    delete the comment

    @author philg@mit.edu
    @author tarik@arsdigita.com
    @creation-date 01/06/99
    @cvs-id delete.tcl,v 3.1.6.5 2000/09/22 01:38:02 kevin Exp
    @param comment_id The comment to delete
    @param return_url The page to return to after transaction completes
} {
    comment_id
    {return_url ""}
}


# Note: if page is accessed through /groups pages then group_id and 
#   group_vars_set are already set up in the environment by the ug_serve_section. 
# group_vars_set contains group related variables (group_id, group_name, 
#   group_short_name, group_admin_email, group_public_url, group_admin_url, 
#   group_public_root_url, group_admin_root_url, group_type_url_p, 
#   group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_scope_error_check
general_comments_admin_authorize $comment_id

set comment_exists_p \
	[db_0or1row comment_check \
	"select comment_id, content, general_comments.html_p as comment_html_p
         from general_comments
         where comment_id = :comment_id"]

if { !$comment_exists_p } {
    db_release_unused_handles
    ad_scope_return_error "Can't find comment" "Can't find comment $comment_id"
    return
}

append doc_body "
[ad_scope_admin_header "Really delete comment"]
[ad_scope_admin_page_title "Really delete comment"]
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
[export_form_vars comment_id return_url]
</form>
[ad_scope_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $doc_body

