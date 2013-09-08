# www/calendar/admin/category-delete.tcl
ad_page_contract {
    If the category is empty, then it deletes the category

    If the category is not empty, then it gives the choice of
    disabling the category or moving everything to another category

    Number of queries: 3

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id category-delete.tcl,v 3.3.2.6 2000/09/22 01:37:06 kevin Exp
    
} {
    category_id:integer
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}


# category-delete.tcl,v 3.3.2.6 2000/09/22 01:37:06 kevin Exp
# File:     /calendar/admin/category-delete.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  category deleteion page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# category_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


ad_scope_error_check

ad_scope_authorize $scope admin group_admin none


# see if there are any calendar entries

set query_num_category_entries "select count(calendar_id) from calendar where category_id=:category_id"

set num_category_entries [db_string num_category_entries $query_num_category_entries]

if { $num_category_entries == 0 } {

    # no calendar entries, so just delete
    ad_returnredirect "category-delete-2.tcl?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]"
    return
}

set query_category "select category
from calendar_categories
where category_id=:category_id"


set category [db_string category $query_category]


set page_content "
[ad_scope_admin_header "Delete Category $category"]
<h2>Delete </h2>
category  <a href=\"category-one?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]\">$category</a>
<hr>

There are entries in the category $category. 
<p>
Would you like to:
<p>
<A href=\"category-delete-2?[export_url_scope_vars category_id]\">Disable $category</a>

<p>
or move all entries to another category: 
<p>
<ul>
"

set query_other_categories "
select category as category_new 
from calendar_categories 
where category <> :category 
and [ad_scope_sql]
and enabled_p <> 'f'
"

set counter 0
db_foreach other_categories $query_other_categories {

    incr counter
    append page_content "<li><a href=\"category-change?[export_url_scope_vars category_new category_id]\">$category_new</a>\n
    "
}

if { $counter == 0 } {
    append page_content "No additional categories are defined"
}

append page_content "

</ul>

[ad_scope_admin_footer]
"

doc_return  200 text/html $page_content

## END FILE category-delete.tcl



