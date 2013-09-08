# /www/admin/chat/delete-messages-2.tcl
ad_page_contract {
    
    Delete messages of a chat room.
    @param chat_room_id chat room identifier
    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @creation-date 11/18/1998
    @cvs-id delete-messages-2.tcl,v 3.1.6.5 2000/07/21 03:56:23 ron Exp

} {
    {chat_room_id:naturalnum,notnull}
}

ad_maybe_redirect_for_registration

db_dml admin_chat_delete_msg_from_chat "delete from chat_msgs where chat_room_id=:chat_room_id"  

db_release_unused_handles

ad_returnredirect "one-room.tcl?[export_url_vars chat_room_id]"
