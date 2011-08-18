# /www/education/util/chat-room-create.tcl
#
# aileen@mit.edu, randyg@arsdigita.com
#
# Feb 2000
#
# based on /admin/chat/create-room.tcl but outside the /admin/ 
# directory so a prof can create chat rooms

set_the_usual_form_variables

# chat_room_id pretty_name, moderated_p, expiration_days, active_p

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

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set group_id [lindex $id_list 1]

if { [empty_string_p $group_id] } {
    set scope_val "public"
} else {
    set scope_val "group"
    # only allow 1 chat room per group
    if {[database_to_tcl_string $db "select count(*) from chat_rooms where group_id=$group_id"]>0} {
	ad_return_complaint 1 "<li>A chat room has already been created for this group"
	return
    }
}

ns_db dml $db "begin transaction"


ns_db dml $db "insert into chat_rooms
(chat_room_id, pretty_name, group_id, scope, moderated_p, expiration_days, active_p)
values
($chat_room_id, '$QQpretty_name', '$group_id', '$scope_val', '$moderated_p', '$expiration_days', '$active_p')"

# create a new admin group within this transaction
ad_administration_group_add $db "$pretty_name Moderation" chat $chat_room_id "/chat/moderate.tcl?chat_room_id=$chat_room_id" "f"

ns_db dml $db "end transaction"

ad_returnredirect "/chat/enter-room.tcl?[export_url_vars chat_room_id]"
