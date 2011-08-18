# /www/education/util/chat-room-create.tcl
#
# aileen@mit.edu, randyg@arsdigita.com
#
# Feb 2000
#
# based on /admin/chat/create-room.tcl but outside the /admin/ directory so a prof can create chat rooms

ad_maybe_redirect_for_registration

set db [ns_db gethandle]
set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set title "Create a Chat Room for $class_name"
set chat_room_id [database_to_tcl_string $db "select chat_room_id_sequence.nextval from dual"]

ns_db releasehandle $db


ns_return 200 text/html "

[ad_header "$title"]

<h2>$title</h2>

[ad_context_bar_ws_or_index [list "[edu_url]class/" "$class_name Home"] [list "[edu_url]class/admin/" "Administration"] $title]

<hr>
<form action=\"chat-room-create-2.tcl\" method=POST>
<table><tr><td align=right>
Room Name:</td><td> <input name=pretty_name size=35></td>
</tr>
<tr><td align=right>
Expire messages after </td><td><input type=text name=expiration_days value=\"\" size=4> days (or leave blank to archive messages indefinitely)
</td></tr>
<tr><td align=right>
Active?</td>
<td>
<select name=active_p>
    <option value=f>No</option>
    <option value=t selected>Yes</option>
</select>
(pick \"No\" if you want to wait before launching this publicly)
</td></tr>
<tr><td align=right>
Moderated?</td>
<td><select name=moderated_p><option value=f selected>No</option>
<option value=t>Yes</option>
</select>
</td></tr>
</table>
<P>
<center>
[export_form_vars chat_room_id]
<input type=submit value=Create>
</center>
</form>

[ad_admin_footer]
"


