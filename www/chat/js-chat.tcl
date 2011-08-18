# $Id: js-chat.tcl,v 3.1.4.1 2000/04/28 15:09:51 carsten Exp $
# File:     /chat/js-chat.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com

# this page isn't particularly efficient but we think it is okay because 
# it isn't called every two seconds; only the chat rows subframe is

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
ad_scope_authorize $db $scope registered group_member none

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set selection [ns_db 0or1row $db "select pretty_name, group_id as private_group_id, moderated_p 
from chat_rooms 
where chat_room_id=$chat_room_id"]

if { $selection == "" } {
    ad_scope_return_error "Room deleted" "We couldn't find chat room $chat_room_id.  It was probably deleted by the site administrator." $db
    return -code return
}

set_variables_after_query

if {[empty_string_p $private_group_id] || [ad_user_group_member $db $private_group_id $user_id]} {
    ReturnHeaders


    ns_write "
	<html>
	<head>
	<title>[chat_system_name]: $pretty_name</title>
	</head>
	<frameset rows=\"100,*,0\" frameborder=no framespacing=5>
	<frame name=formpage marginwidth=10 marginheight=0  src=\"js-form.tcl?[export_url_scope_vars chat_room_id]\">
	<frame name=chat_rows marginwidth=10 marginheight=0 src=\"js-chat-rows.tcl?[export_url_scope_vars chat_room_id]#most_recent\">
	<frame name=refresh marginwidth=0 marginheight=0 src=\"js-refresh.tcl?[export_url_scope_vars chat_room_id]\">
	</frameset>
	<noframes>
	<html>
	<body bgcolor=yellow>
	This version of chat requires a modern browser.
	</body>
	</html>"
} else {
    ad_returnredirect index.tcl?[export_url_scope_vars]
}

