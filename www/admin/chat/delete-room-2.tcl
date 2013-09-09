# /www/admin/chat/delete-room-2.tcl
ad_page_contract {
    Delete a chat room.

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @param chat_room_id chat room identifier
    @creation-date 11/18/1998
    @cvs-id delete-room-2.tcl,v 3.1.6.6 2000/07/21 03:56:24 ron Exp

} {
    {chat_room_id:naturalnum,notnull}
}

ad_maybe_redirect_for_registration

db_transaction {

    # delete the admin group we were using for moderation

    set admin_group_id [ad_administration_group_id chat $chat_room_id]
    if ![empty_string_p $admin_group_id] {

	db_dml admin_chat_delete_user_group_map_queue {delete from user_group_map_queue where group_id = :admin_group_id}
	db_dml admin_chat_delete_user_group_map {delete from user_group_map where group_id = :admin_group_id}
    }
    db_dml admin_chat_delete_room_delete_chat_msgs {delete from chat_msgs where chat_room_id=:chat_room_id}
    db_dml admin_chat_delete_chat_room {delete from chat_rooms where chat_room_id=:chat_room_id}

} on_error {
    # All is okay--it was already gone
}

db_release_unused_handles

ad_returnredirect index.tcl
