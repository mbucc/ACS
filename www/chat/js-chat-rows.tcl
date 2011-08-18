# $Id: js-chat-rows.tcl,v 3.0.4.1 2000/04/28 15:09:51 carsten Exp $
# File:     /chat/js-chat-rows.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com

# this page will be the most frequently requested in the entire ACS
# it must be super efficient
# it must not query the RDBMS except in unusual cases (e.g., private chat) 

# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#       are already set up in the environment by the ug_serve_section. group_vars_set 
#       contains group related variables (group_id, group_name, group_short_name, 
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables

# chat_room_id
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]
ns_db releasehandle $db

set private_group_id [chat_room_group_id $chat_room_id]

if { ![empty_string_p $private_group_id] && ![ad_user_group_member_cache $private_group_id $user_id]} {
    ad_returnredirect "bounced-from-private-room.tcl?[export_url_scope_vars chat_room_id]"
    return
}

# throw an error if this isn't a pure integer
validate_integer "chat_room_id" $chat_room_id
ns_return 200 text/html [util_memoize "chat_js_entire_page $chat_room_id"]

