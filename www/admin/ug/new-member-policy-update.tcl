ad_page_contract {
    @param group_id the ID of the group
    @param new_member_policy the new member policy of this group
    
    @cvs-id new-member-policy-update.tcl,v 3.2.6.4 2000/07/21 03:58:20 ron Exp
} {
    group_id:notnull,naturalnum
    new_member_policy:notnull
}


db_dml update_ug_nmp "update user_groups set new_member_policy = :new_member_policy where group_id = :group_id"

if { $new_member_policy == "open" } {
    # grant everyone in the queue membership
    
    db_transaction {
    
    db_dml grant_queued_memberships "insert into user_group_map (user_id, group_id, mapping_ip_address,  role, mapping_user) select user_id, group_id, ip_address, 'member', [ad_get_user_id] from user_group_map_queue where group_id = :group_id and not exists (select user_id from user_group_map where user_group_map.user_id = user_group_map_queue.user_id and group_id = :group_id and role = 'member')"

    db_dml flush_ugmap_queue "delete from user_group_map_queue where group_id = :group_id"

    }

}

ad_returnredirect "group?[export_url_vars group_id]"