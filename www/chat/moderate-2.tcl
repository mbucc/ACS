# moderate-2.tcl,v 1.3.2.2 2000/02/03 09:45:36 ron Exp
# File:     /chat/moderate-2.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com

# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#       are already set up in the environment by the ug_serve_section. group_vars_set 
#       contains group related variables (group_id, group_name, group_short_name, 
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables

# moderateXXXXX, ids, chat_room_id
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]

set private_group_id [chat_room_group_id $chat_room_id]

if { ![empty_string_p $private_group_id] && ![ad_user_group_member_cache $private_group_id $user_id]} {
    ad_returnredirect "bounced-from-private-room.tcl?[export_url_scope_vars chat_room_id]"
    return
}
switch $scope {
    public {
	if { ![ad_administration_group_member $db chat $chat_room_id $user_id] } {
	    ad_scope_return_error "Not Moderator" "You are not a moderator for this chat room." $db
	    return
	}
    }
    group {
	if { ![ad_permission_p $db "" "" "" $user_id $group_id]==1 } {
	    ad_scope_return_error "Not Moderator" "You are not a moderator for this chat room." $db
	    return
	}
    }
}


foreach chat_msg_id $ids {
    set new_approved_p [expr $[set dummy "moderate$chat_msg_id"]]
    ns_db dml $db "update chat_msgs 
set approved_p='$new_approved_p' 
where chat_msg_id = $chat_msg_id
and chat_room_id = $chat_room_id"
}

util_memoize_flush "chat_entire_page $chat_room_id short"
util_memoize_flush "chat_entire_page $chat_room_id medium"
util_memoize_flush "chat_entire_page $chat_room_id long"
util_memoize_flush "chat_js_entire_page $chat_room_id"

util_memoize "chat_entire_page $chat_room_id short"
util_memoize "chat_entire_page $chat_room_id medium"
util_memoize "chat_entire_page $chat_room_id long"
util_memoize "chat_js_entire_page $chat_room_id"

ad_returnredirect moderate.tcl?[export_url_scope_vars chat_room_id]


