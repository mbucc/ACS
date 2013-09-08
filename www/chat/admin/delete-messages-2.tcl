# /www/admin/chat/delete-messages-2.tcl

ad_page_contract {
    deletes messages of a chat room
    
    @author aure@arsdigita.com
    @author philg@mit.edu
    @author ahmeds@arsdigita.com
    @param chat_room_id
    @param scope room is a "public", "group" or "user"
    @creation-date 1998-11-18
    @cvs-id delete-messages-2.tcl,v 1.4.2.6 2000/07/22 23:08:17 david Exp

} {
    {chat_room_id:naturalnum,notnull}
    {scope:optional}
}

ad_maybe_redirect_for_registration

set user_id [ad_scope_authorize $scope admin group_admin none]
db_dml chat_admin_delete_messages_2 {delete from chat_msgs where chat_room_id=:chat_room_id}
db_release_unused_handles 

ad_returnredirect "one-room.tcl?[export_url_scope_vars chat_room_id]"
