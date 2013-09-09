# group-name-edit-2.tcl
ad_page_contract {
    actually updates the group_name column in the user_groups table

    @param group_id the ID of the group
    @param group_name the name of the new group
    
    @cvs-id group-name-edit-2.tcl,v 3.1.6.6 2000/07/21 03:58:15 ron Exp
} {
    group_id:notnull,naturalnum
    group_name:notnull
}

db_dml update_ug_name "update user_groups 
set group_name = :group_name
where group_id = :group_id"

ad_returnredirect "group?group_id=$group_id"

