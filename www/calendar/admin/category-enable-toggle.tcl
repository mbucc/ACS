# www/calendar/admin/category-enable-toggle.tcl
ad_page_contract {
    Flips the enabled_p bit

    Number of dml: 1

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id category-enable-toggle.tcl,v 3.2.2.3 2000/07/21 03:59:03 ron Exp
    
} {
    category_id:integer
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}


# category-enable-toggle.tcl,v 3.2.2.3 2000/07/21 03:59:03 ron Exp
# File:     /calendar/admin/category-enable-toggle.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  enables/disables a category
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# category_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

set query_toggle "
update calendar_categories 
set enabled_p = logical_negation(enabled_p) 
where category_id = :category_id"

db_dml toggle $query_toggle

ad_returnredirect "category-one.tcl?[export_url_scope_vars category_id]"

## END FILE category-enable-toggle.tcl