ad_page_contract {
    @param group_id the Id of the group
    @param role the role to remove

    @cvs-id role-delete.tcl,v 3.2.2.4 2000/07/21 03:58:20 ron Exp
} {
    group_id:notnull,naturalnum
    role:notnull
}

db_dml delete_group_role "delete from user_group_roles
where group_id = :group_id
and role = :role"
db_release_unused_handles

ad_returnredirect "group?group_id=$group_id"

