# $Id: category-delete.tcl,v 3.0.4.1 2000/04/28 15:09:48 carsten Exp $
# File:     /calendar/admin/category-delete.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  category deleteion page
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
# category_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

# see if there are any calendar entries

set num_category_entries [database_to_tcl_string $db "
select count(calendar_id) from calendar where category_id=$category_id"]

if { $num_category_entries == 0 } {

    # no calendar entries, so just delete
    ad_returnredirect "category-delete-2.tcl?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]"
    return
}

set category [database_to_tcl_string $db "
select category
from calendar_categories
where category_id=$category_id"]

ReturnHeaders
ns_write "
[ad_scope_admin_header "Delete Category $category" $db]
<h2>Delete </h2>
category  <a href=\"category-one.tcl?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]\">$category</a>
<hr>



There are entries in the database that currently are categories with the category $category. 
<p>
Would you like to:
<p>
<A href=\"category-delete-2.tcl?[export_url_scope_vars category_id]\">Leave these items with category $category</a>

<p>
or change the category to one of the following:
<p>
<ul>
"
set counter 0
foreach category_new [database_to_tcl_list $db "
select category as category_new 
from calendar_categories 
where category <> '$category' 
and [ad_scope_sql]
and enabled_p <> 'f'"] {

    incr counter
    ns_write "<li><a href=\"category-change.tcl?[export_url_scope_vars category_new category_id]\">$category_new</a>\n
"
}

if { $counter == 0 } {
    ns_write "no event categories are currently defined; this is an
error in system configuration and you should complain to 
[calendar_system_owner]"
}

ns_write "

</ul>

[ad_scope_admin_footer]
"
 
