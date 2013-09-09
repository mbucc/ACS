ad_page_contract {
    @param group_id the Id of the group
    @param role the role to add

    @cvs-id role-add.tcl,v 3.1.6.4 2000/07/21 03:58:20 ron Exp
} {
    group_id:notnull,naturalnum
    role:notnull
}


ad_user_group_role_add $group_id $role

ad_returnredirect "group?group_id=$group_id"

