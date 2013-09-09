# group-shortname-edit-2.tcl
ad_page_contract {
     actually updates the short_name column in the user_groups table
    @param group_id the ID of the group
    @param short_name a short name of the group
 
    @cvs-id group-shortname-edit-2.tcl,v 3.1.6.5 2000/07/21 03:58:15 ron Exp
} {
    group_id:notnull,naturalnum
    short_name:notnull
}

db_dml user_group_sn_update  "update user_groups 
set short_name = :short_name
where group_id = :group_id"

ad_returnredirect "group?group_id=$group_id"

