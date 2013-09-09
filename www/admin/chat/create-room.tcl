# www/admin/chat/create-room.tcl
ad_page_contract {
    Creates a new chat room.

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @creation-date 18 November 1999
    @cvs-id create-room.tcl,v 3.2.2.6 2000/09/22 01:34:28 kevin Exp
} {

}

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set title "Create a Room"

# Build up the list of group options for the chat room.
set bind_vars [ad_tcl_vars_to_ns_set user_id]
set group_options_widget [ad_db_optionlist -bind $bind_vars admin_chat_select_group_name "
    select unique group_name, 
        user_groups.group_id
    from user_groups, user_group_map
    where user_groups.group_id=user_group_map.group_id
        and user_group_map.user_id=:user_id 
        and user_groups.group_type <> 'administration'
    order by group_name"] 


set page_content "[ad_admin_header "$title"]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Chat System"] "$title"]

<hr>
<form action=\"create-room-2\" method=POST>
<table><tr><td align=right>
Room Name:</td><td> <input name=pretty_name size=35></td>
</tr>
<tr>
<td align=right>
Restrict to Members of a Group:</Td><td>
<select name=group_id>
<option value=\"\">No Group, this is a Public Chat Room</option>
$group_options_widget
</select></td></tr>
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
<input type=submit value=Create>
</center>
</form>

[ad_admin_footer]
"


doc_return  200 text/html $page_content









