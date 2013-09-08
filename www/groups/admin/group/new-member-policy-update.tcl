#   /groups/admin/group/new-member-policy-update.tcl

ad_page_contract {
    @param new_member_policy the new member policy 

    @cvs-id new-member-policy-update.tcl,v 3.3.2.5 2000/07/26 23:12:44 ryanlee Exp
sets the new member policy for the group

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)

} {
    new_member_policy:notnull
}


if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

db_dml update_ug_nm_policy "
update user_groups 
set new_member_policy = :new_member_policy 
where group_id = :group_id"

if { $new_member_policy == "open" } {
    # grant everyone in the queue membership
    
    db_transaction {
    
    db_dml grant_all_queued_members "
    insert into user_group_map 
    (user_id, group_id, mapping_ip_address,  role, mapping_user) 
    select user_id,
           group_id,
           ip_address,
           'member',
           [ad_get_user_id] 
      from user_group_map_queue 
     where group_id = :group_id 
       and not exists (select user_id 
                         from user_group_map 
                        where user_group_map.user_id = user_group_map_queue.user_id 
                          and group_id = :group_id
                          and role = 'member')"

    db_dml delete_queued_members "
        delete from user_group_map_queue where group_id = :group_id"

    } on_error {
	ad_return_error "Database error" "The database is complaining:\n<pre>$errmsg\n</pre>\n"
	return
    }
}

db_release_unused_handles

ad_returnredirect members

