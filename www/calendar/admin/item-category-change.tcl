# www/calendar/admin/item-category-change.tcl
ad_page_contract {
    Displays a page for changing the category of a calendar item

    Number of queries: 2

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id item-category-change.tcl,v 3.2.2.5 2000/09/22 01:37:06 kevin Exp
    
} {
    calendar_id:integer
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}

# item-category-change.tcl,v 3.2.2.5 2000/09/22 01:37:06 kevin Exp
# File:     /calendar/admin/item-category-change.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  changes category of one item
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# calendar_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}



ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

set query_item_title "select title from calendar where calendar_id = :calendar_id"

set title [db_string item_title $query_item_title]

set page_content "
[ad_scope_admin_header "Pick New Category for $title"]
[ad_scope_admin_page_title "Pick new category for <a href=\"item?[export_url_scope_vars]&calendar_id=$calendar_id\">$title</a>"]  
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] [list "item.tcl?[export_url_scope_vars calendar_id]" "One Item"] "Pick Category"]
<hr>

<ul>
"

set counter 0

set ad_scope_sql_value [ad_scope_sql]

set query_categories "
select category 
from calendar_categories 
where enabled_p = 't'
and $ad_scope_sql_value
"

db_foreach categories $query_categories {

    incr counter

    append page_content "<li><a href=\"item-category-change-2?[export_url_scope_vars category calendar_id]\">$category</a>\n"
}

append page_content "

</ul>

[ad_scope_admin_footer]
"

doc_return  200 text/html $page_content

## END FILE item-category-change.tcl




