#/www/chat/moderate-2.tcl
ad_page_contract {
    Target page for moderate.

    <b>Note:<b> If the page is accessed through /groups pages then group_id and group_vars_set are already set up in the environment by the ug_serve_section.<br>
    group_vars_set contains group related variables (group_id, group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chat_room_id
    @param ids
    @param moderateXXXXX This is the message id
    @param scope
    @param owner_id note that owner_id is the user_id of the user who owns this module (when scope=user)
    @param group_vars_set
    @param on_which_group
    @param on_what_id

    @creation-date 18 November 1998
    @cvs-id moderate-2.tcl,v 3.3.2.5 2000/07/21 03:59:08 ron Exp
} {
    chat_room_id:naturalnum,notnull
    ids:notnull
    moderate:array
    scope:optional
    owner_id:optional,naturalnum
    group_vars_set:optional,naturalnum
    on_which_group:optional,naturalnum
    on_what_id:optional,naturalnum

}



# moderate.XXXXX, ids, chat_room_id

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

set private_group_id [chat_room_group_id $chat_room_id]

if { ![empty_string_p $private_group_id] && ![ad_user_group_member_cache $private_group_id $user_id]} {
    ad_returnredirect "bounced-from-private-room.tcl?[export_url_scope_vars chat_room_id]"
    return
}
switch $scope {
    public {
	if { ![ad_administration_group_member chat $chat_room_id $user_id] } {
	    ad_scope_return_error "Not Moderator" "You are not a moderator for this chat room."
	    return
	}
    }
    group {
	if { ![ad_permission_p "" "" "" $user_id $group_id]==1 } {
	    ad_scope_return_error "Not Moderator" "You are not a moderator for this chat room."
	    return
	}
    }
}


foreach chat_msg_id $ids {
    set new_approved_p [expr $[set dummy "moderate($chat_msg_id)"]]
    db_dml chat_moderate_chat_update_msgs {update chat_msgs 
set approved_p=:new_approved_p 
where chat_msg_id = :chat_msg_id
and chat_room_id = :chat_room_id}
}

util_memoize_flush "chat_entire_page $chat_room_id short"
util_memoize_flush "chat_entire_page $chat_room_id medium"
util_memoize_flush "chat_entire_page $chat_room_id long"
util_memoize_flush "chat_js_entire_page $chat_room_id"

util_memoize "chat_entire_page $chat_room_id short"
util_memoize "chat_entire_page $chat_room_id medium"
util_memoize "chat_entire_page $chat_room_id long"
util_memoize "chat_js_entire_page $chat_room_id"

db_release_unused_handles
ad_returnredirect moderate.tcl?[export_url_scope_vars chat_room_id]


