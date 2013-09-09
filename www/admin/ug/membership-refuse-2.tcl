
ad_page_contract {
    @param group_id the id of the group
    @param user_id the id of the refused user

    @cvs-id membership-refuse-2.tcl,v 3.1.6.4 2000/07/22 07:27:12 ryanlee Exp
} {
    group_id:notnull,naturalnum
    user_id:notnull,naturalnum
}


db_dml ugmq_delete_user "delete from user_group_map_queue where
user_id = :user_id and group_id = :group_id"

ad_returnredirect "group?[export_url_vars group_id]"