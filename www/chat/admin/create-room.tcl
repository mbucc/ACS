# /www/chat/admin/create-room.tcl

ad_page_contract {
    Creates a new chat room
    
    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @param scope is this room a "public", "group" or "user" room
    @creation-date 1998-11-18
    @cvs-id create-room.tcl,v 1.4.2.8 2000/09/22 01:37:13 kevin Exp
} {
    {scope "public"}
}

set user_id [ad_scope_authorize $scope admin group_admin none]

set title "Create a Room"

set page_content "
[ad_scope_admin_header "$title"]
[ad_scope_admin_page_title $title]
[ad_scope_admin_context_bar [list "index.tcl" Chat] $title]
<hr>
<form action=\"create-room-2\" method=POST>
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


doc_return  200 text/html $page_content







