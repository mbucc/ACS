# /www/chat/admin/delete-room.tcl

ad_page_contract {

    Display confirmation before delete a chat room

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @param chat_room_id chat room to delete
    @param scope is this room "public", "user", or "group"
    @creation-date 11/18/1998
    @cvs-id delete-room.tcl,v 1.4.2.7 2000/09/22 01:37:14 kevin Exp
} {
    {chat_room_id:naturalnum,notnull}
    scope
}

set user_id [ad_scope_authorize $scope admin group_admin none]
set exists [db_0or1row chat_admin_delete_room_get_room_name {
    select pretty_name from chat_rooms where chat_room_id = :chat_room_id}]

if { $exists == 0 } {
    ad_return_error "Not Found" "Could not find chat_room $chat_room_id"
    return
}

set page_content "
[ad_scope_admin_header "Confirm deletion of $pretty_name"]
[ad_scope_admin_page_title $pretty_name]
[ad_scope_admin_context_bar [list "index.tcl" Chat] [list "one-room.tcl?[export_url_vars chat_room_id]" "One Room"] "Confirm Deletion"]

<hr>

Are you sure that you want to delete $pretty_name (and its 
[db_string chat_admin_delete_room_confirm_msg_count "select count(*) from chat_msgs where chat_room_id = :chat_room_id"] messages)?

<p>

<center>
<form method=GET action=\"delete-room-2\">
[export_form_scope_vars chat_room_id]
<input type=submit value=\"Yes, I'm sure\">
</form>
</center>

[ad_scope_admin_footer]
"



doc_return  200 text/html $page_content
