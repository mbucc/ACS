
ad_page_contract {
    @param user_id the user Id to grant
    @param group_id the Group to grant permission on

    @cvs-id membership-grant.tcl,v 3.2.6.4 2000/07/22 07:26:47 ryanlee Exp
} {
    user_id:notnull,naturalnum
    group_id:notnull,naturalnum
}


db_transaction {

db_dml insert_ugm_permission "insert into user_group_map (user_id, group_id, mapping_ip_address,  role, mapping_user) select user_id, group_id, ip_address, 'member', [ad_get_user_id] from user_group_map_queue where user_id = :user_id and group_id = :group_id and not exists (select user_id from user_group_map where user_id = :user_id and group_id = :group_id and role = 'member')"

db_dml delete_from_ugm_queue "delete from user_group_map_queue where user_id = :user_id and group_id = :group_id"

}

ad_returnredirect "group?[export_url_vars group_id]"