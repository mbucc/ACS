#/www/chat/admin/delete-room-2.tcl
ad_page_contract {
    Delete a chat room from db

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @param chat_room_id room id to delete message from
    @param scope scope of this room
    @creation-date 11/18/1998
    @cvs-id delete-room-2.tcl,v 1.4.2.6 2000/07/21 03:59:09 ron Exp
} {
    {chat_room_id:naturalnum,notnull}
    {scope:optional}
}

ad_maybe_redirect_for_registration

set user_id [ad_scope_authorize $scope admin group_admin none]

db_transaction {

    # delete the admin group we were using for moderation

    set admin_group_id [ad_administration_group_id chat $chat_room_id]

    if ![empty_string_p $admin_group_id] {
	db_dml chat_admin_delete_room_user_map {delete from user_group_map_queue where group_id = :admin_group_id}
	db_dml chat_admin_delete_room_group_map {delete from user_group_map where group_id = :admin_group_id}
    }

    db_dml chat_admin_delete_room_msgs {delete from chat_msgs where chat_room_id=:chat_room_id}

    db_dml chat_admin_delete_room_final {delete from chat_rooms where chat_room_id=:chat_room_id}

} on_error {
    # It's okay, continue
}

db_release_unused_handles

ad_returnredirect "index.tcl?[export_url_scope_vars]"
