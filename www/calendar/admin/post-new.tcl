# www/calendar/admin/post-new.tcl
ad_page_contract {
    Begins 4-step process of adding a new calendar item by
    displaying a list of enabled categories

    Number of queries: 1

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id post-new.tcl,v 3.2.2.7 2000/09/22 01:37:07 kevin Exp

} {
    {scope public}
    {user_id:naturalnum ""}
    {group_id:naturalnum ""}
    {on_what_id:naturalnum ""}
    {on_which_group:naturalnum ""}
}

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set user_id [ad_scope_authorize $scope admin group_admin none]

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set page_content "
[ad_scope_admin_header "Select category for new event"]
[ad_scope_admin_page_title "Select category for new event"]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] "Pick Category"]

<hr>

<ul>
"



db_foreach enabled_categories "
select category, category_id
from calendar_categories
where [ad_scope_sql]
" {
  
    append page_content "<li><a href=\"post-new-2?[export_url_scope_vars]&[export_url_vars category category_id]\">$category</a>\n"

} if_no_rows {
    
    append page_content "
    No categories have been defined.  Please
    <a href=\"categories?[export_url_scope_vars]\">add categories</a>."
    
}

db_release_unused_handles

append page_content "

</ul>

[ad_scope_admin_footer]
"

doc_return  200 text/html $page_content

## END FILE post-new.tcl

