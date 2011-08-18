# create-room-2.tcl,v 1.3.2.1 2000/02/03 09:20:13 ron Exp
# File:     admin/chat/create-room-2.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  creates a new chat room

set_the_usual_form_variables

# pretty_name, maybe group_id, moderated_p, expiration_days, active_p

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

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

set chat_room_id [database_to_tcl_string $db "select chat_room_id_sequence.nextval from dual"]

if { [empty_string_p $group_id] } {
    set scope_val "public"
} else {
    set scope_val "group"
}


ns_db dml $db "insert into chat_rooms
(chat_room_id, pretty_name, group_id, scope, moderated_p, expiration_days, active_p)
values
($chat_room_id, '$QQpretty_name', '$group_id', '$scope_val', '$moderated_p', '$expiration_days', '$active_p')"

# create a new admin group within this transaction
ad_administration_group_add $db "$pretty_name Moderation" chat $chat_room_id "/chat/moderate.tcl?chat_room_id=$chat_room_id" "f"

ns_db dml $db "end transaction"

ad_returnredirect "one-room.tcl?[export_url_vars chat_room_id]"
