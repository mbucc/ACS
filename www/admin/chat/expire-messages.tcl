# /admin/chat/expire-messages.tcl

ad_page_contract {
    Delete expired messages of a chat room

    @param chat_room_id chat room identifier
    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @creation-date 1998-11-18
    @cvs-id expire-messages.tcl,v 3.1.2.6 2000/09/22 01:34:29 kevin Exp
} {
    {chat_room_id:naturalnum,notnull}
}

ad_maybe_redirect_for_registration

set expiration_days [db_string admin_chat_get_expiration_days {select expiration_days from chat_rooms where chat_room_id=:chat_room_id}]

if {[empty_string_p $expiration_days]} {
    ad_return_complaint 1 "You haven't set expiration_days so we
couldn't possibly delete any messages"
    return
}

db_dml admin_chat_remove_expire_msgs {delete from chat_msgs 
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
