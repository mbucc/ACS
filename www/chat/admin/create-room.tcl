# create-room.tcl,v 1.4.2.1 2000/02/03 09:20:14 ron Exp
# File:     admin/chat/create-room.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  creates a new chat room

set_the_usual_form_variables 0


set db [ns_db gethandle]

set user_id [ad_scope_authorize $db $scope admin group_admin none]
ReturnHeaders

set title "Create a Room"

ns_write "
[ad_scope_admin_header "$title" $db]
[ad_scope_admin_page_title $title $db]
[ad_scope_admin_context_bar [list "index.tcl" Chat] $title]
<hr>
<form action=\"create-room-2.tcl\" method=POST>
[export_form_scope_vars]
<table><tr><td align=right>
Room Name:</td><td> <input name=pretty_name size=35></td>
</tr>
<tr>
<td align=right>
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
<input type=submit value=Create>
</center>
</form>

[ad_scope_admin_footer]
"





