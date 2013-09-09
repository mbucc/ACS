# /www/admin/chat/delete-messages.tcl

ad_page_contract {

    Display confirmation that messages of this chat about to get delete.
    
    @author Aure (aure@arsdigita.com)
    @param chat_room_id delete message from this room
    @param scope is this room "public", "user" or "group"

    @creation-date 2000-01-31
    @cvs-id delete-messages.tcl,v 1.4.2.7 2000/09/22 01:37:14 kevin Exp 

} {
    {chat_room_id:naturalnum,notnull}
    {scope:optional}
}

set user_id [ad_scope_authorize $scope admin group_admin none]
set exists [db_0or1row chat_admin_delete_messages_list {
    select pretty_name from chat_rooms where chat_room_id = :chat_room_id}]

if { $exists == 0} {
    ad_return_error "Not Found" "Could not find chat_room $chat_room_id"
    return
}


set message_count [db_string chat_admin_delete_messages_msg_count {select count(*) from chat_msgs where chat_room_id = :chat_room_id}]

set page_content "
[ad_scope_admin_header "Confirm deletion of messages in $pretty_name"]
[ad_scope_admin_page_title "Confirm deletion of messages in $pretty_name"]
[ad_scope_admin_context_bar [list "index.tcl" Chat] [list "one-room.tcl?[export_url_scope_vars chat_room_id]" "One Room"] "Confirm Deletion"]

<hr>

Are you sure that you want to delete $message_count messages from $pretty_name?

<p>

<center>
<form method=GET action=\"delete-messages-2\">
[export_form_scope_vars chat_room_id]
<input type=submit value=\"Yes, I'm sure\">
</form>
</center>

[ad_admin_footer]
"



doc_return  200 text/html $page_content
