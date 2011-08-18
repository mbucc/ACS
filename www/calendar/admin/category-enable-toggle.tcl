# $Id: category-enable-toggle.tcl,v 3.0.4.1 2000/04/28 15:09:49 carsten Exp $
# File:     /calendar/admin/category-enable-toggle.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  enables/disables a category
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# category_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

ns_db dml $db "
update calendar_categories 
set enabled_p = logical_negation(enabled_p) 
where category_id = $category_id"

ad_returnredirect "category-one.tcl?[export_url_scope_vars category_id]"

