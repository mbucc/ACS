#/www/chat/enter-room.tcl
ad_page_contract {

    Purpose:  enters into a  chat room

    Note: if page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
    
    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @creation-date 11/18/1998
    @param chat_room_id Enter in this chat room
    @param scope scope of the chat room
    @param owner_id 
    @param group_id 
    @param on_which_group 
    @param on_what_id 
    @cvs-id enter-room.tcl,v 3.4.2.5 2000/07/21 03:59:06 ron Exp
} {
    {chat_room_id:naturalnum,notnull}
    {scope:optional}
    {owner_id:optional}
    {group_id:optional}
    {on_which_group:optional}
    {on_what_id:optional}
}

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

chat_post_system_note "has entered the room" $user_id $chat_room_id

set moderated_p [db_string chat_enter_room_get_moderate_option {select moderated_p from chat_rooms where chat_room_id = :chat_room_id}]

db_release_unused_handles
switch $scope {
    public {
	if { [ad_administration_group_member chat $chat_room_id $user_id] && \
		($moderated_p == "t") } {
	    ad_returnredirect moderate.tcl?[export_url_scope_vars chat_room_id]
	} else {
	    ad_returnredirect chat.tcl?[export_url_scope_vars chat_room_id]
	}
    }
    group {
	if { ($moderated_p == "t") && ([ad_permission_p "" "" "" $user_id $group_id]==1)} {
	    # this chat is moderated and I am an administrator for this group.
	    ad_returnredirect moderate.tcl?[export_url_scope_vars chat_room_id]
	} else {
	    ad_returnredirect chat.tcl?[export_url_scope_vars chat_room_id]
	}
    }
}














