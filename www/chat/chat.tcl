# /www/chat/chat.tcl
ad_page_contract {

    Chat room
    
    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chat_room_id chat in this room
    @param n_rows number of messages to display. Valid options are "short", "medium", "long"
    @param scope scope of this chat room ("public", "group" or "user")
    @param owner_id
    @param group_id
    @param on_which_group
    @param on_what_id
    @creation-date 11/18/1998
    @cvs-id chat.tcl,v 3.4.2.9 2000/09/22 01:37:07 kevin Exp
} {
    {chat_room_id:naturalnum,notnull}
    {n_rows "short"}
    {scope:optional}
    {owner_id:optional,naturalnum}
    {group_id:optional,naturalnum}
    {on_which_group:optional}
    {on_what_id:optional}
}

# chat_room_id, n_rows (has three possible values, "short", "medium", "long"; we do 
# this for caching)
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ns_log notice "hi"
ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

if { ![info exists n_rows] || [empty_string_p $n_rows] || ($n_rows != "long" && $n_rows != "short" && $n_rows != "medium") } {
    set n_rows "short"
}

set private_group_id [chat_room_group_id $chat_room_id]

if { ![empty_string_p $private_group_id] && ![ad_user_group_member_cache $private_group_id $user_id]} {
    ad_returnredirect "bounced-from-private-room.tcl?[export_url_scope_vars chat_room_id]"
    return
}
# make sure that these are integers before passing them
# to memoize, which does an eval 
doc_return  200 text/html [util_memoize "chat_entire_page $chat_room_id $n_rows"]



