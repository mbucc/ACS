ad_page_contract {
    @param action the action to be performed
    @param group_id the id of the group to perform the action on 
    @param role the role of the user
    @cvs-id action-role-unmap.tcl,v 3.2.2.4 2000/07/21 03:58:11 ron Exp

} {
    group_id:notnull,naturalnum
    action:notnull
    role:notnull
}


db_dml delete_ugarm "delete from 
user_group_action_role_map
where group_id = :group_id 
and role = :role and action = :action"
db_release_unused_handles

ad_returnredirect "group?group_id=$group_id"

