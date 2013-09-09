# /www/chat/exit-room.tcl
ad_page_contract {

    Purpose:  exits a  chat room

    Note: if page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
    
    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chat_room_id exit this room
    @param newlocation redirect to this url after exiting
    @param scope
    @param owner_id
    @param group_id
    @param on_which_group
    @param on_what_id
    @creation-date 11/18/1998
    @cvs-id exit-room.tcl,v 3.2.2.4 2000/07/21 03:59:06 ron Exp
} {
    {chat_room_id:naturalnum,notnull}
    {newlocation:notnull}
    {scope:optional}
    {owner_id:optional}
    {group_id:optional}
    {on_which_group:optional}
    {on_what_id:optional}
}


# chat_room_id, newlocation
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check


set user_id [ad_scope_authorize $scope registered group_member none]

chat_post_system_note "has left the room" $user_id $chat_room_id

db_release_unused_handles    
ad_returnredirect $newlocation

