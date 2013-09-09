ad_page_contract {
    @param action the action to be performed
    @param group_id the id of the group to perform the action on 

    @cvs-id action-add.tcl,v 3.1.6.4 2000/07/25 08:19:08 kevin Exp

} {
    group_id:notnull,naturalnum
    action:notnull
}

ad_user_group_action_add $group_id $action

ad_returnredirect "group?group_id=$group_id"




