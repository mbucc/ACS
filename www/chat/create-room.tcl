# $Id: create-room.tcl,v 3.1 2000/03/01 08:45:05 yon Exp $
# File:     /chat/create-room.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  creates a new chat room

# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#       are already set up in the environment by the ug_serve_section. group_vars_set 
#       contains group related variables (group_id, group_name, group_short_name, 
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0

# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]

ReturnHeaders

set title "Create a Room"

ns_write "

[ad_scope_header "$title" $db]
[ad_scope_page_title "$title" $db]
[ad_scope_context_bar_ws [list "index.tcl?[export_url_scope_vars]" [chat_system_name]] "$title"]

<hr>
<form action=create-room-2.tcl method=get>
[export_form_scope_vars]

<table><tr><td align=right>
Room Name:</td><td> <input name=pretty_name size=35></td>
</tr>
<tr>
<td align=right>
Limit to Members of this Group:</td><td>
<select name=group_id>
<option value=\"\">No Group, this is a Public Chat Room</option>
"


set sql "select unique group_name, group_id
from user_groups
where ad_group_member_p ( $user_id, group_id ) = 't'
order by group_name"

ns_write "
[ad_db_optionlist $db $sql]
</select></td></tr>
<tr><td align=right>
Moderation Policy:</td>
<td><select name=moderated_p><option value=f>Unmoderated</option>
<option value=t>I will be the moderator (all posts go through me)</option>
</select>
</td></tr>
<tr><td></td><td>
<input type=submit value=Create>
</form>
</td></tr></table>
[ad_scope_footer]
"


