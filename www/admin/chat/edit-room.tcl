# /www/admin/chat/edit-room.tcl
ad_page_contract {

    Update the properties of the chat room.

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @param chat_room_id chat room identifier
    @param pretty_name  Nice description of a chat room
    @param group_id group id this chat room belongs to
    @param user_id_from_search user id
    @param moderated_p is this room require approval for message posting
    @param expiration_days number of day to expire message
    @param active_p is this room active
    @creation-date 11/18/1998
    @cvs-id edit-room.tcl,v 3.2.2.5 2000/07/21 03:56:24 ron Exp
} {
    {chat_room_id:naturalnum,notnull}
    {pretty_name:trim,notnull}
    {group_id:naturalnum,optional}
    {user_id_from_search:optional}
    {expiration_days:optional,integer}
    moderated_p
    active_p
}

ad_maybe_redirect_for_registration

if { [empty_string_p $group_id] } {
    set scope_sql "group_id = null,
                   scope = 'public', "
} else {
    set scope_sql "group_id = :group_id,
                   scope = 'group', "
}

db_dml admin_chat_update_chat_room_info "update chat_rooms
set pretty_name=:pretty_name, 
moderated_p=:moderated_p,
$scope_sql
active_p=:active_p,
expiration_days=:expiration_days
where chat_room_id=:chat_room_id"

db_release_unused_handles
ad_returnredirect "one-room.tcl?[export_url_vars chat_room_id]"

