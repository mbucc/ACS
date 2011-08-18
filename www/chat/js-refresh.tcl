# $Id: js-refresh.tcl,v 3.0 2000/02/06 03:36:48 ron Exp $
# File:     /chat/js-referesh.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com

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
ns_db releasehandle $db

ReturnHeaders

set last_post_id [chat_last_post $chat_room_id]

ns_write "
<meta http-equiv=\"Refresh\" content=\"[ad_parameter JavaScriptRefreshInterval chat 5]\">
<script language=javascript>
var newest_post=$last_post_id;

function load_new () {
    if (newest_post != top.chat_rows.last_post) top.chat_rows.location = 'js-chat-rows.tcl?[export_url_scope_vars chat_room_id]&random=$last_post_id';
}
</script>
<body bgcolor=white onLoad=\"load_new()\">
"