# /groups/admin/group/membership-refuse-2.tcl

ad_page_contract {
    @param user_id the user ID of the refusee
deny membership to user who applied for it (used only for groups,
           which heave new members policy set to wait)

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)

    @cvs-id membership-refuse-2.tcl,v 3.1.6.4 2000/07/24 19:07:29 ryanlee Exp
} {
    user_id:notnull,naturalnum
}



db_dml delete_ugm_queue_blackball "
delete from user_group_map_queue where
user_id = :user_id and group_id = :group_id
"

ad_returnredirect members
