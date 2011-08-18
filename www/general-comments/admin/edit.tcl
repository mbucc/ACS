# $Id: edit.tcl,v 3.0.4.1 2000/04/28 15:10:38 carsten Exp $
# File:     /general-comments/admin/edit.tcl
# Date:     01/06/99
# author :  philg@mit.edu
# Contact:  philg@mit.edu, tarik@arsdigita.com
# Purpose:  edit comment page
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
# comment_id
# maybe return_url

ad_scope_error_check 
set db [ns_db gethandle]
set admin_id [general_comments_admin_authorize $db $comment_id]

if { $admin_id == 0 } {
    # we don't know who this is administering, 
    # so we won't be able to audit properly
    ad_returnredirect "/register/"
    return
}

set selection [ns_db 1row $db "
select comment_id, content, general_comments.html_p as comment_html_p, approved_p
from general_comments
where comment_id = $comment_id"]

set_variables_after_query

ReturnHeaders

ns_write "
[ad_scope_admin_header "Edit comment" $db]
[ad_scope_admin_page_title "Edit comment" $db]
[ad_scope_admin_context_bar [list "index.tcl" "General Comments"] "Edit"]
<hr>

<blockquote>
<form action=edit-2.tcl method=post>
<textarea name=content cols=70 rows=10 wrap=soft>[philg_quote_double_quotes $content]</textarea><br>
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
[export_form_scope_vars comment_id return_url]
</form>
</blockquote>
[ad_scope_admin_footer]
"
