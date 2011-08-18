# $Id: delete-file.tcl,v 3.0 2000/02/06 03:16:06 ron Exp $
# File:     admin/custom-sections/delete-file.tcl
# Date:     12/30/99
# Contact:  ahmeds@arsdigita.com
# Purpose:  deletes custom section page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ReturnHeaders

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# content_file_id section_id

ad_scope_error_check

set db [ns_db gethandle]

ad_scope_authorize $db $scope admin group_admin none

set exception_count 0
set exception_text ""

set page_title "Delete Page Confirmation"

set section_pretty_name [database_to_tcl_string $db "
    select section_pretty_name 
    from content_sections 
    where section_id = $section_id"]

ns_write "
[ad_scope_admin_header $page_title $db]
[ad_scope_admin_page_title $page_title $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars section_id]" $section_pretty_name] [list "edit-page.tcl?[export_url_scope_vars content_file_id section_id]" "Page Property"] $page_title]

<hr>
<br>

<blockquote>
<h3>Confirm Page Deletion</h3>
<br>

<b>Warning:</b> Are you sure you want to delete this page 

<br><br>Are you sure you want to proceed ?

<form method=get action=\"delete-file-2.tcl\">
[export_form_scope_vars  content_file_id section_id]
<input name=confirm_deletion value=yes type=submit>
[ad_space 5]<input name=confirm_deletion value=no type=submit>
</form>

</blockquote>

[ad_scope_admin_footer]
"