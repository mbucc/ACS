# $Id: message.tcl,v 3.0 2000/02/06 03:36:49 ron Exp $
# File:     /chat/message.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com

# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#       are already set up in the environment by the ug_serve_section. group_vars_set 
#       contains group related variables (group_id, group_name, group_short_name, 
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables

# chatter_id
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]

set pretty_name [database_to_tcl_string $db "select first_names||' '||last_name from users where user_id=$chatter_id"]

set html "
[ad_scope_header "$pretty_name" $db]
<script runat=client>
function helpWindow(file) {
    window.open(file,'ACSchatWindow','toolbar=no,location=no,directories=no,status=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=480')
}
</script>

[ad_scope_page_title $pretty_name $db]
[ad_scope_context_bar [list "/pvt/home.tcl" "Your Workspace"] [list "index.tcl?[export_url_scope_vars]" [chat_system_name]] "$pretty_name"]

<hr>
"

set formhtml "
<form method=post action=post-personal-message.tcl>
<table><tr><td valign=top align=right>
Chat:</td><td> <textarea wrap name=msg rows=2 cols=30></textarea>
[export_form_scope_vars chatter_id]
</td><td valign=top> <a href=message.tcl?[export_url_scope_vars chatter_id]>See new messages without posting</a><br>
<a href=index.tcl?[export_url_scope_vars]>Exit this room</a>
</td>
</tr>
<tr><td></td><td><input type=submit value=\"Send message\"></td></tr></table>
</form>
"

if {[ad_parameter MostRecentOnTopP chat]} {
    append html $formhtml
    set formhtml ""
}

set chat_rows [chat_get_personal_posts $chatter_id]
ns_db releasehandle $db

ReturnHeaders
ns_write "
$html
<ul>
$chat_rows
</ul>
$formhtml
</ul>

<a href=\"javascript:helpWindow('js-message.tcl?[export_url_scope_vars chatter_id]')\">Open javascript version of this room</a>

</ul>

[ad_scope_footer]
"




