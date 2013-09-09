#/www/chat/admin/expire-messages.tcl
ad_page_contract {
    Delete expire messages of a chat room

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chat_room_id chat room to expire messages
    @creation-date 11/18/1998
    @cvs-id expire-messages.tcl,v 1.3.2.5 2000/09/22 01:37:14 kevin Exp
} {
    {chat_room_id:notnull,naturalnum}
}

ad_maybe_redirect_for_registration

set expiration_days [db_string chat_admin_get_expire_message_days {
    select expiration_days from chat_rooms where chat_room_id=:chat_room_id}]

if {[empty_string_p $expiration_days]} {
    ad_return_complaint 1 "You haven't set expiration_days so we
couldn't possibly delete any messages"
    return
}

db_dml chat_admin_expire_messages_delete {delete from chat_msgs 
where chat_room_id = :chat_room_id
and creation_date < sysdate-:expiration_days}

set n_rows_deleted [db_resultrows]

set page_content "[ad_admin_header "$n_rows_deleted rows were deleted"]

<h2>$n_rows_deleted rows deleted</h2>

[ad_admin_context_bar [list "index.tcl" Chat] [list "one-room.tcl?[export_url_vars chat_room_id]" "One Room"] "Deleted Expired Messages"]

<hr>

[ad_admin_footer]
"




doc_return  200 text/html $page_content


