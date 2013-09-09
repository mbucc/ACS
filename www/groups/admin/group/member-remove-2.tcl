# /groups/admin/group/member-remove-2.tcl

ad_page_contract {
    @param user_id the ID of the user to remove

    @cvs-id member-remove-2.tcl,v 3.1.6.4 2000/07/24 18:58:23 ryanlee Exp

    
remove member from the user group

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)

} {
    user_id:notnull,naturalnum
}

if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

db_dml delete_ugm_user "
delete from user_group_map where
user_id = :user_id and group_id = :group_id"
db_release_unused_handles

ad_returnredirect members
