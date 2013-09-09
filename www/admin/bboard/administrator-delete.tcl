# /www/admin/bboard/administrator-delete.tcl
ad_page_contract {
    Page to remove an administrator from a bboard topic

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic
    @param admin_group_id the ID of the group associated with the topic
    @param user_id the ID of the user to remove
} {
    topic
    topic_id:integer
    admin_group_id:integer
    user_id:integer
}

# -----------------------------------------------------------------------------

db_dml admin_delete "
delete from user_group_map
where  user_id  = :user_id
and    group_id = :admin_group_id"

ad_returnredirect "topic-administrators.tcl?[export_url_vars topic topic_id]"

