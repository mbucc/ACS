# $Id: category-delete-2.tcl,v 3.0.4.1 2000/04/28 15:09:48 carsten Exp $
# File:     /calendar/admin/category-delete-2.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  category deletion target page
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

# see if there are any calendar entries

set num_category_entries [database_to_tcl_string $db "
select count(calendar_id) from calendar where category_id=$category_id"]

if {$num_category_entries > 0} {

  ns_db dml $db "update calendar_categories set enabled_p ='f' where category_id=$category_id"

} else {

    ns_db dml $db "delete from calendar_categories where category_id=$category_id"

}

ad_returnredirect "categories.tcl?[export_url_scope_vars]"

