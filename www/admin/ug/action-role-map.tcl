ad_page_contract {
    @param action the action to be performed
    @param group_id the id of the group to perform the action on 
    @param role the role of the user
    @cvs-id action-role-map.tcl,v 3.2.2.5 2000/07/21 22:13:22 ryanlee Exp
} {
    group_id:notnull,naturalnum
    action:notnull
    role:notnull
}

set ip_address [ns_conn peeraddr]

# insert the row if it was not there
db_dml putnew_ugarm "insert into user_group_action_role_map (group_id, role, action, creation_user, creation_ip_address) select :group_id, :role, :action, [ad_get_user_id], :ip_address from dual where not exists (select role from user_group_action_role_map where group_id = :group_id and role = :role and action = :action)"
db_release_unused_handles

ad_returnredirect "group?group_id=$group_id"

