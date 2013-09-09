# /www/admin/chat/delete-messages.tcl
ad_page_contract {
    Display confirmation before delete chat room message.

    @author Aure (aure@arsdigita.com)
    @param chat_room_id chat room identifier
    @creation-date 01/31/2000
    @cvs-id delete-messages.tcl,v 3.2.2.6 2000/09/22 01:34:28 kevin Exp

} {
    {chat_room_id:naturalnum,notnull}
}

set selection [db_0or1row admin_chat_get_chat_room_name {select pretty_name from chat_rooms where chat_room_id = :chat_room_id}]

if { $selection == 0 } {
    ad_return_error "Not Found" "Could not find chat_room $chat_room_id"
    return
}

set page_content "[ad_admin_header "Confirm deletion of messages in [ns_quotehtml $pretty_name]"]

<h2>Confirm deletion of messages in [ns_quotehtml $pretty_name]</h2>

[ad_admin_context_bar [list "index.tcl" Chat] [list "one-room.tcl?[export_url_vars chat_room_id]" "One Room"] "Confirm Deletion"]

<hr>

Are you sure that you want to delete [db_string admin_chat_count_msgs_in_room {select count(*) from chat_msgs where chat_room_id = :chat_room_id}] messages from $pretty_name?

<p>

<center>
<form method=GET action=\"delete-messages-2\">
[export_form_vars chat_room_id]
<input type=submit value=\"Yes, I'm sure\">
</form>
</center>

[ad_admin_footer]
"


doc_return  200 text/html $page_content

