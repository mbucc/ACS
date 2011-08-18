# $Id: delete-file-2.tcl,v 3.0.4.1 2000/04/28 15:08:33 carsten Exp $
# File:     admin/custom-sections/delete-file-2.tcl
# Date:     12/30/99
# Contact:  ahmeds@arsdigita.com
# Purpose:  deletes a custom section page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)


set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# content_file_id  section_id confirm_deletion

ad_scope_error_check

set db [ns_db gethandle]

ad_scope_authorize $db $scope admin group_admin none

if { $confirm_deletion =="yes" } {
    ns_db dml $db "
    delete from content_files
    where content_file_id=$content_file_id
    "
}

ad_returnredirect "index.tcl?[export_url_vars section_id]"




