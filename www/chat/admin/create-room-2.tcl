# /www/admin/chat/create-room-2.tcl

ad_page_contract {

    Creates a new chat room

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @param pretty_name Name of the chat room
    @param group_id group this chat room belongs to
    @param moderated_p is this room require approval for posting message.
    @param expiration_days number of days to archive the message
    @param active_p is this room ready to use
    @creation-date 1998-11-18
    @cvs-id create-room-2.tcl,v 1.4.2.6 2000/07/21 03:59:09 ron Exp
    
} {
    pretty_name
    {group_id:naturalnum,optional ""}
    moderated_p
    {expiration_days:integer ""}
    active_p
}

ad_maybe_redirect_for_registration

set exception_count 0 
set exception_text ""

if {[empty_string_p $pretty_name]} {
    incr exception_count
    append exception_text "<li>Please name your chat room."
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

db_transaction {

    set chat_room_id [db_string chat_admin_chat_create_room_next_id "select chat_room_id_sequence.nextval from dual"]

    if { [empty_string_p $group_id] } {
	set scope_val "public"
    } else {
	set scope_val "group"
    }

    db_dml chat_admin_create_room_insert {insert into chat_rooms
                        (chat_room_id, pretty_name, group_id, scope, moderated_p, expiration_days, active_p)
    values (:chat_room_id, :pretty_name, :group_id, :scope_val, :moderated_p, :expiration_days, :active_p)}

    # create a new admin group within this transaction
     ad_administration_group_add "$pretty_name Moderation" chat $chat_room_id "/chat/moderate.tcl?chat_room_id=$chat_room_id" "f"



} on_error {
    db_release_unused_handles 
    ad_return_complaint 1 "Error in transaction: $errmsg"
    exit 0
}

db_release_unused_handles 

ad_returnredirect "one-room.tcl?[export_url_vars chat_room_id]"








