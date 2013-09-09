# www/calendar/admin/item-category-change-2.tcl
ad_page_contract {
    Performs the dml to change an item's category 
    and redirects to admin/item.tcl

    Number of queries: 1
    Number of dml: 1

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id item-category-change-2.tcl,v 3.2.2.4 2000/07/21 03:59:04 ron Exp
    
} {
    calendar_id:integer
    category:notnull
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}



# item-category-change-2.tcl,v 3.2.2.4 2000/07/21 03:59:04 ron Exp
# File:     /calendar/admin/item-category-change-2.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  changes category of one item
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# calendar_id,  category
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

set query_category_id "
select category_id 
from calendar_categories
where category = :category
and [ad_scope_sql]
"

set category_id [db_string category_id $query_category_id]

set dml_update_category "update calendar set category_id=:category_id where calendar_id=:calendar_id"

db_dml update_category $dml_update_category


## HMMmmm some success/failure code would be nice in here -MJS


ad_returnredirect "item.tcl?[export_url_scope_vars calendar_id]"

## END FILE item-category-change-2.tcl