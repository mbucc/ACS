# $Id: new-member-policy-update.tcl,v 3.1.2.1 2000/04/28 15:09:34 carsten Exp $
set_form_variables

# group_id, new_member_policy

set db [ns_db gethandle]

ns_db dml $db "update user_groups set new_member_policy = '$new_member_policy' where group_id = $group_id"

if { $new_member_policy == "open" } {
    # grant everyone in the queue membership
    
    ns_db dml $db "begin transaction"
    
    ns_db dml $db "insert into user_group_map (user_id, group_id, mapping_ip_address,  role, mapping_user) select user_id, group_id, ip_address, 'member', [ad_get_user_id] from user_group_map_queue where group_id = $group_id and not exists (select user_id from user_group_map where user_group_map.user_id = user_group_map_queue.user_id and group_id = $group_id and role = 'member')"

    ns_db dml $db "delete from user_group_map_queue where group_id = $group_id"

    ns_db dml $db "end transaction"

}

ad_returnredirect "group.tcl?[export_url_vars group_id]"