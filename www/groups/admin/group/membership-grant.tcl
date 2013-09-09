# /groups/admin/group/membership-grant.tcl

ad_page_contract {
    @param user_id The user ID to grant membership to

    @cvs-id membership-grant.tcl,v 3.3.2.5 2000/07/26 23:27:13 ryanlee Exp


grant membership to user who applied for it (used only for groups,
           which heave new members policy set to wait)

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

db_transaction {

db_dml insert_new_ug_member "
insert into user_group_map 
(user_id, group_id, mapping_ip_address,  role, mapping_user) 
     select user_id,
            group_id,
            ip_address,
            'member',
            [ad_get_user_id] 
       from user_group_map_queue 
      where user_id = :user_id
        and group_id = :group_id 
        and not exists (select user_id 
                          from user_group_map 
                         where user_id = :user_id
                           and group_id = :group_id
                           and role = 'member')"

db_dml delete_ug_map_queue "
delete from user_group_map_queue 
where user_id = :user_id and group_id = :group_id
"

} on_error {
    ad_return_error "Page error" "The database is complaining:\n<pre>\n$errmsg\n</pre>\n"
    return
}

db_release_unused_handles

ad_returnredirect members


