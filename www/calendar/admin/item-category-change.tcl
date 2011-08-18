# $Id: item-category-change.tcl,v 3.0 2000/02/06 03:36:11 ron Exp $
# File:     /calendar/admin/item-category-change.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  changes category of one item
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}
set_the_usual_form_variables 0
# calendar_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none


set title [database_to_tcl_string $db "select title from calendar
where calendar_id = $calendar_id"]

ReturnHeaders
ns_write "
[ad_scope_admin_header "Pick New Category for $title" $db]
[ad_scope_admin_page_title "Pick new category for <a href=\"item.tcl?[export_url_scope_vars]&calendar_id=$calendar_id\">$title</a>" $db]  
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] [list "item.tcl?[export_url_scope_vars calendar_id]" "One Item"] "Pick Category"]
<hr>

<ul>
"

set counter 0
foreach category [database_to_tcl_list $db "
select category 
from calendar_categories 
where enabled_p = 't'
and [ad_scope_sql]"] {
    incr counter
    ns_write "<li><a href=\"item-category-change-2.tcl?[export_url_scope_vars category calendar_id]\">$category</a>\n"
}

ns_write "

</ul>

[ad_scope_admin_footer]
"
 
