# $Id: bounced-from-private-room.tcl,v 3.0 2000/02/06 03:36:22 ron Exp $
# File:     /chat/bounced-from-private-room.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com

# this page explains to user why he was bounced 
# and links him over to the group user page if he wants 
# to apply for membership

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
ad_scope_authorize $db $scope registered group_member none

set selection [ns_db 1row $db "select cr.pretty_name, cr.group_id as private_group_id, ug.group_name
from chat_rooms cr , user_groups ug
where cr.chat_room_id = $chat_room_id
and cr.group_id = ug.group_id"]

set_variables_after_query

ns_return 200 text/html "

[ad_scope_header "Private Room" $db]
[ad_scope_page_title "Private Room" $db]
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [chat_system_name]] "Private Room"]

<hr>

The chat room \"$pretty_name\" is private.  You have to be a member of
<a href=\"/ug/group.tcl?[export_url_scope_vars]&group_id=$private_group_id\">$group_name</a>
to participate.


[ad_scope_footer]
"


