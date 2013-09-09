# /www/chat/js-form.tcl

ad_page_contract {

    If page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chat_room_id
    @param scope
    @param owner_id
    @param group_id
    @param on_which_group
    @param on_what_id
    @creation-date 1998-11-18
    @cvs-id js-form.tcl,v 3.4.2.5 2000/09/22 01:37:11 kevin Exp
} {
    chat_room_id:naturalnum,notnull
    scope:optional
    owner_id:naturalnum,optional
    group_id:naturalnum,optional
    on_which_group:naturalnum,optional
    on_what_id:naturalnum,optional
}

ad_scope_error_check

ad_scope_authorize $scope registered group_member none

set page_content "
<html>
<script language=javascript>
function SubmitForm() {
    document.hidden.msg.value=document.visible.msg.value;
    document.hidden.submit();
    document.visible.msg.value=\"\";
    document.visible.msg.reset();
    document.visible.msg.focus();
}
</script>
<body bgcolor=white onLoad=\"document.visible.msg.focus()\">
<center>

<form name=visible>
<table>

<tr>
<td valign=top>
<textarea wrap=physical name=msg rows=2 cols=30></textarea>
</td>

<td valign=top><input type=button value=\"Post\" onClick=\"SubmitForm()\">
[export_form_scope_vars chat_room_id]
</td>

<td valign=top>
</td>
</tr>
</table>
</form>

<form name=hidden target=chat_rows method=post action=js-post-message>
<input type=hidden name=msg>
[export_form_scope_vars chat_room_id]
</form>
</body>
</html>
"



doc_return  200 text/html $page_content





