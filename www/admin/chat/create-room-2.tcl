# www/admin/chat/create-room-2.tcl
ad_page_contract {
    Creates a new chat room - does the actual db insert.
    
    @param group_id room identifier
    @param moderate_p is this require approval for posting message
    @param expiration_days number of days to keep the message
    @param active_p is this room active  ('t' or 'f')
    @param pretty_name descriptive name for a chat room
    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @creation-date 18 November 1999
    @cvs-id create-room-2.tcl,v 3.2.2.6 2000/07/21 03:56:23 ron Exp
} {
    {group_id:naturalnum,optional}
    {moderated_p:optional}
    {expiration_days:integer,optional}
    {active_p:optional}
    {pretty_name:notnull,trim}
}

ad_maybe_redirect_for_registration

db_transaction {

    set chat_room_id [db_string admin_chat_chat_room_id_nextval {select chat_room_id_sequence.nextval from dual}]

    if { [empty_string_p $group_id] } {
        set scope_val "public"
    } else {
        set scope_val "group"
    }

    db_dml admin_chat_chat_room_create {insert into chat_rooms
    (chat_room_id, pretty_name, group_id, scope, moderated_p, expiration_days, active_p)
    values
    (:chat_room_id, :pretty_name, :group_id, :scope_val, :moderated_p, :expiration_days, :active_p)}

    # Create a new admin group within this transaction.
    ad_administration_group_add "$pretty_name Moderation" chat $chat_room_id "/chat/moderate.tcl?chat_room_id=$chat_room_id" "f" $group_id 

} on_error {
    # All is okay here?  I suspect transaction is for atomicity.
}



db_release_unused_handles
ad_returnredirect "one-room.tcl?[export_url_vars chat_room_id]"


