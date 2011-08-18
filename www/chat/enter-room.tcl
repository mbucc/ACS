# enter-room.tcl,v 1.3.2.1 2000/02/03 09:45:11 ron Exp
# File:     /chat/enter-room.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  enters into a  chat room

# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#       are already set up in the environment by the ug_serve_section. group_vars_set 
#       contains group related variables (group_id, group_name, group_short_name, 
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)


set_the_usual_form_variables 0

# chat_room_id
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]

chat_post_system_note $db "has entered the room" $user_id $chat_room_id
switch $scope {
    public {
	if { [ad_administration_group_member $db chat $chat_room_id $user_id] } {
	    ad_returnredirect moderate.tcl?[export_url_scope_vars chat_room_id]
	} else {
	    ad_returnredirect chat.tcl?[export_url_scope_vars chat_room_id]
	}
    }
    group {
	set moderated_p [database_to_tcl_string $db "select moderated_p from chat_rooms where
	chat_room_id = $chat_room_id"]
	if { ($moderated_p == "t") && ([ad_permission_p $db "" "" "" $user_id $group_id]==1)} {
	    # this chat is moderated and I am an administrator for this group.
	    ad_returnredirect moderate.tcl?[export_url_scope_vars chat_room_id]
	} else {
	    ad_returnredirect chat.tcl?[export_url_scope_vars chat_room_id]
	}
    }
}

