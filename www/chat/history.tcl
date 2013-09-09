# /chat/history.tcl

ad_page_contract {
    This page lists the history of a chat room.  
    
    If the page is accessed through /groups pages then group_id and group_vars_set  
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author Aurelius Prochazka (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param owner_id owner_id is the user_id of the user who owns this module (when scope=user)
    @param scope
    @param chat_room_id
    @param group_id
    @param group_vars
    @param on_which_group_id
    @param on_what_id
    @creation-date 1999-11-18
    @cvs-id history.tcl,v 3.2.2.10 2000/09/22 01:37:09 kevin Exp
} {
    chat_room_id:naturalnum,notnull
    scope:optional
    owner_id:naturalnum,optional
    group_id:naturalnum,optional
    group_vars_set:optional
    on_which_group_id:naturalnum,optional
    on_what_id:naturalnum,optional
}

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]


set private_group_id [chat_room_group_id $chat_room_id]

if { ![empty_string_p $private_group_id] && 
     ![ad_user_group_member_cache $private_group_id $user_id] } {
    ad_returnredirect "bounced-from-private-room?[export_url_scope_vars chat_room_id]"
    return
}

doc_return  200 text/html [util_memoize "chat_history $chat_room_id" [ad_parameter RoomPropertiesCacheTimeout chat 600]]






