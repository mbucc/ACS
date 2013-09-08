# www/calendar/admin/category-change.tcl
ad_page_contract {
    Moves all items from one category to another? (by name)

    Number of queries: 1
    Number of dml: 1

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id category-change.tcl,v 3.2.2.4 2000/07/21 03:59:03 ron Exp
    
} {
    category_id:naturalnum
    category_new
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

# category_id, category_new
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)




ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

set exception_count 0
set exception_text ""

if { ![info exists category_new] || [empty_string_p $category_new] } {
    incr exception_count
    append exception_text "<li>Please enter a category."
}

if {$exception_count > 0} { 
    ad_scope_return_complaint $exception_count $exception_text
    return
}

db_1row category_new_id "
select category_id as category_new_id
from calendar_categories 
where category = :category_new
and [ad_scope_sql] "


set dml_update_new_category "
update calendar
set category_id=:category_new_id
where category_id = :category_id"

if [catch { db_dml update_new_category $dml_update_new_category } errmsg] {
    
    # there was some other error with the category
    ad_scope_return_error "Error updating category" "We couldn't update your category. Here is what the database returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    "
    return
}

ad_returnredirect "category-one.tcl?[export_url_scope_vars]&category_id=[ns_urlencode $category_new_id]"

## END FILE category-change.tcl
