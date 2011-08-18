# $Id: create-room-2.tcl,v 3.0.4.1 2000/04/28 15:09:50 carsten Exp $
# File:     /chat/create-room-2.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  creates a new chat room

# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#       are already set up in the environment by the ug_serve_section. group_vars_set 
#       contains group related variables (group_id, group_name, group_short_name, 
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)


set_the_usual_form_variables 0

# pretty_name, maybe group_id, moderated_p
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]

set exception_count 0 
set exception_text ""

if {[empty_string_p $pretty_name]} {
    incr exception_count
    append exception_text "<li>Please name your new chat room."
}

if {$exception_count > 0} {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}


ns_db dml $db "begin transaction"

set chat_room_id [database_to_tcl_string $db "select chat_room_id_sequence.nextval from dual"]

ns_db dml $db "insert into chat_rooms
(chat_room_id, pretty_name, moderated_p, [ad_scope_cols_sql])
values
($chat_room_id, '$QQpretty_name', '$moderated_p', [ad_scope_vals_sql])"

# regardless of whether or not this person wants to moderate, we'll make an 
# admin group
ad_administration_group_add $db "$QQpretty_name Moderator" chat $chat_room_id "/chat/moderate.tcl?[export_url_scope_vars chat_room_id]" "f"

# if this person is going to moderate 
if { $moderated_p == "t" } {
    ad_administration_group_user_add $db $user_id "administrator" "chat" $chat_room_id
}

ns_db dml $db "end transaction"

ad_returnredirect "/chat/chat.tcl?[export_url_scope_vars chat_room_id]"

