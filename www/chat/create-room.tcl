# /www/chat/create-room.tcl

ad_page_contract {

    Creates a new chat room. Getting information about the new chat room.

    Note: if page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author aure@arsdigita.com
    @author philg@mit.edu
    @author ahmeds@arsdigita.com
    @param scope scope of page
    @param owner_id who will own this chat room
    @param group_id group id of owner?
    @param on_which_group
    @param on_what_id

    @creation-date 11/18/1998
    @cvs-id create-room.tcl,v 3.4.2.7 2000/09/22 01:37:08 kevin Exp
} {
    {scope:optional "public"}
    {owner_id:optional}
    {group_id:optional}
    {on_which_group:optional}
    {on_what_id:optional}
}

# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

if { ![ad_parameter UsersCanCreateRoomsP Chat] } {
set page_content " 

[ad_scope_header "Can't Create Room"]
[ad_scope_page_title "Can't Create Room"]
[ad_scope_context_bar_ws [list "index.tcl?[export_url_scope_vars]" [chat_system_name]] "Can't Create Room"]
<hr>
Creating Room by normal user is disabled on this server. Please contact the administrator. 

[ad_scope_footer]"

} else {

if { ![info exists scope] } { set scope "public" }

set user_id [ad_scope_authorize $scope registered group_member none]

set title " Create a Room"

set page_content "

[ad_scope_header "$title"]
[ad_scope_page_title "$title"]
[ad_scope_context_bar_ws [list "index.tcl?[export_url_scope_vars]" [chat_system_name]] "$title"]

<hr>
<form action=create-room-2 method=get>
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

append page_content "
[ad_db_optionlist chat_get_unique_group $sql]
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
}
doc_return  200 text/html $page_content











