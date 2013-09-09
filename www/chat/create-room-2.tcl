# /www/chat/create-room-2.tcl
ad_page_contract {

    Purpose:  creates a new chat room

    Note: if page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
    
    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param pretty_name  chat room name
    @param group_id group id if this room belongs to a group
    @param moderated_p is this room requires approval for posting messages
    @param scope scope of this chat room, either "public", "private" or "group"
    @param owner_id
    @param group_id
    @param on_which_group
    @param on_what_id
    @creation_date 11/18/1998
    @cvs-id create-room-2.tcl,v 3.2.2.7 2000/07/25 09:02:19 kevin Exp
} {
    {pretty_name:notnull,trim}
    {group_id:optional,naturalnum}
    {moderated_p:notnull}
    {scope:optional "public"}
    {owner_id:optional,naturalnum}
    {group_id:optional,naturalnum}
    {on_which_group:optional}
    {on_what_id:optional,naturalnum}
}

# pretty_name, maybe group_id, moderated_p
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]


db_transaction {

    set chat_room_id [db_string chat_create_room_next_id "select chat_room_id_sequence.nextval from dual"]

    db_dml chat_create_room_insert "insert into chat_rooms
    (chat_room_id, pretty_name, moderated_p, [ad_scope_cols_sql])
    values (:chat_room_id, :pretty_name, :moderated_p, [ad_scope_vals_sql])" 

    # regardless of whether or not this person wants to moderate, we'll make an 
    # admin group

    # if this person is going to moderate 
    if { $moderated_p == "t" } {
	ad_administration_group_user_add $user_id "administrator" "chat" $chat_room_id
    }

} on_error {
    ad_return_complaint 1 "Error in transaction: $errmsg"
    exit 0
}


 ad_administration_group_add  "$pretty_name Moderator" "chat" $chat_room_id "/chat/moderate.tcl?[export_url_scope_vars chat_room_id]" "f"

db_release_unused_handles
ad_returnredirect "/chat/chat.tcl?[export_url_scope_vars chat_room_id]"








