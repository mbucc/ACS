# edit-room.tcl,v 1.3.2.1 2000/02/03 09:20:20 ron Exp
# File:     admin/chat/edit-room.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  edits properties of a chat room

set_the_usual_form_variables

# pretty_name, maybe group_id, moderated_p, user_id_from_search, expiration_days, active_p

ad_maybe_redirect_for_registration

set exception_count 0 
if {[empty_string_p $pretty_name]} {
    incr exception_count
    append exception_text "<li>Please give this chat room a name."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [ns_db gethandle]

if { [empty_string_p $group_id] } {
    set scope_sql "group_id = null,
                   scope = 'public', "
} else {
    set scope_sql "group_id = $group_id,
                   scope = 'group', "
}

ns_db dml $db "update chat_rooms
set pretty_name='$QQpretty_name', 
moderated_p='$moderated_p',
$scope_sql
active_p='$active_p',
expiration_days= [ns_dbquotevalue $expiration_days number]
where chat_room_id=$chat_room_id"

ad_returnredirect "one-room.tcl?[export_url_scope_vars chat_room_id]"










