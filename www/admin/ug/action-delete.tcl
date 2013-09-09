ad_page_contract {
    @param action the action to be performed
    @param group_id the id of the group to perform the action on 

    @cvs-id action-delete.tcl,v 3.1.6.4 2000/07/21 03:58:11 ron Exp
} {
    group_id:notnull,naturalnum
    action:notnull
}

db_dml delete_action "delete from user_group_actions
where group_id = :group_id
and action = :action"

db_release_unused_handles

ad_returnredirect "group?group_id=$group_id"

