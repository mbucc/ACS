# $Id: js-form-good.tcl,v 3.0 2000/02/06 03:36:37 ron Exp $
# File:     /chat/js-form-good.tcl
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

ns_write "
<script language=javascript>
function SubmitForm() {
    document.hidden.msg.value=document.visible.msg.value;
    document.hidden.submit();
    document.visible.msg.value=\"\";
    document.visible.msg.focus();
}
</script>
<center><table><tr>

<form name=visible>
<td valign=top align=right>Chat:</td><td><textarea wrap=physical name=msg rows=2 cols=20></textarea></td><td valign=top>
<a  href='javascript:SubmitForm();'> <img src=/chat/post-message.gif width=96 height=25 border=0></a>
</td>
</tr>
</table>
</form>
<form name=hidden target=chat_rows method=post action=js-post-message.tcl>
<input type=hidden name=msg>
[export_form_scope_vars chat_room_id]
</form>

"


