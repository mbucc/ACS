# /www/chat/js-chat-rows.tcl

ad_page_contract {

    Note: if page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    this page will be the most frequently requested in the entire ACS
    it must be super efficient
    it must not query the RDBMS except in unusual cases (e.g., private chat) 

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @param chat_room_id
    @param scope
    @param owner_id
    @param group_id
    @param on_what_id
    @creation-date 1998-11-18
    @cvs-id js-chat-rows.tcl,v 3.1.6.7 2000/09/22 01:37:09 kevin Exp
} {
    {chat_room_id:naturalnum,notnull}
    {scope ""}
    {owner_id:naturalnum,optional}
    {group_id:naturalnum,optional}
    {on_what_id:naturalnum,optional}

}

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

set private_group_id [chat_room_group_id $chat_room_id]

if { ![empty_string_p $private_group_id] && ![ad_user_group_member_cache $private_group_id $user_id]} {
    ad_returnredirect "bounced-from-private-room.tcl?[export_url_scope_vars chat_room_id]"
    return
}


doc_return  200 text/html [util_memoize "chat_js_entire_page $chat_room_id"]

