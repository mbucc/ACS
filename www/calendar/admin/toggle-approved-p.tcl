# www/calendar/admin/toggle-approved-p.tcl
ad_page_contract {
    This page is called from admin/item.tcl
    and simply changes the approval flag for the item

    Number of dml: 1

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id toggle-approved-p.tcl,v 3.2.2.4 2000/07/21 03:59:05 ron Exp
    
} {
    calendar_id:naturalnum
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

# calendar_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)


## No security, no error handling.  Nice.  

ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

db_dml toggle_approval "update calendar 
set approved_p = logical_negation(approved_p) 
where calendar_id = :calendar_id"

db_release_unused_handles

ad_returnredirect "item.tcl?[export_url_scope_vars calendar_id]"

## END FILE toggle-approved-p.tcl









