# $Id: delete.tcl,v 3.0 2000/02/06 03:44:07 ron Exp $
# File:     /general-comments/admin/delete.tcl
# Date:     01/06/99
# author :  philg@mit.edu
# Contact:  philg@mit.edu, tarik@arsdigita.com
# Purpose:  delete the comment
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# comment_id, maybe return_url

ad_scope_error_check
set db [ns_db gethandle]
general_comments_admin_authorize $db $comment_id

set selection [ns_db 0or1row $db "
select comment_id, content, general_comments.html_p as comment_html_p
from general_comments
where comment_id = $comment_id"]

if { $selection == "" } {
   ad_scope_return_error "Can't find comment" "Can't find comment $comment_id"
   return
}

set_variables_after_query

ReturnHeaders

ns_write "
[ad_scope_admin_header "Really delete comment" $db]
[ad_scope_admin_page_title "Really delete comment" $db]
<hr>

<form action=delete-2.tcl method=post>
Do you really wish to delete the following comment?
<blockquote>
[util_maybe_convert_to_html $content $comment_html_p]
</blockquote>
<center>
<input type=submit name=submit value=\"Proceed\">
<input type=submit name=submit value=\"Cancel\">
</center>
[export_form_scope_vars comment_id return_url]
</form>
[ad_scope_admin_footer]
"
