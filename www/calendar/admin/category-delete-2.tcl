# www/calendar/admin/category-delete-2.tcl
ad_page_contract {
    Performs a delete on a category that has been verified as empty

    Number of queries: ?
    Number of dml: ?

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id category-delete-2.tcl,v 3.2.2.3 2000/07/21 03:59:03 ron Exp
    
} {
    category_id:integer
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}


# category-delete-2.tcl,v 3.2.2.3 2000/07/21 03:59:03 ron Exp
# File:     /calendar/admin/category-delete-2.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  category deletion target page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# category_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

ad_scope_authorize $scope admin group_admin none


# see if there are any calendar entries

set query_num_entries "select count(calendar_id) from calendar where category_id=:category_id"

set num_entries [db_string num_entries $query_num_entries]

if {$num_entries > 0} {

    set dml_disable_category "update calendar_categories set enabled_p ='f' where category_id=:category_id"

    db_dml disable_category $dml_disable_category

} else {

    set dml_delete_category "delete from calendar_categories where category_id=:category_id"

    db_dml delete_category $dml_delete_category

}

ad_returnredirect "categories.tcl?[export_url_scope_vars]"

## END FILE category-delete-2.tcl