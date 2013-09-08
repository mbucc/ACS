ad_page_contract {
    This page shows messages.

    <b>Note:<b> If the page is accessed through /groups pages then group_id and group_vars_set are already set up in the environment by the ug_serve_section.<br>
    group_vars_set contains group related variables (group_id, group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chatter_id
    @param scope
    @param owner_id note that owner_id is the user_id of the user who owns this module (when scope=user)
    @param group_vars_set
    @param on_which_group
    @param on_what_id

    @creation-date 18 November 1998
    @cvs-id message.tcl,v 3.1.6.7 2000/09/22 01:37:13 kevin Exp
} {
    chatter_id:naturalnum,notnull
    scope:optional
    owner_id:optional,naturalnum
    group_vars_set:optional,naturalnum
    on_which_group:optional,naturalnum
    on_what_id:optional,naturalnum

}

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

set pretty_name [db_string chat_message_get_chatter_name {select first_names||' '||last_name from users where user_id=:chatter_id}]

set page_content "
[ad_scope_header "$pretty_name"]
<script runat=client>
function helpWindow(file) {
    window.open(file,'ACSchatWindow','toolbar=no,location=no,directories=no,status=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=480')
}
</script>

[ad_scope_page_title $pretty_name]
[ad_scope_context_bar [list "/pvt/home.tcl" "Your Workspace"] [list "index.tcl?[export_url_scope_vars]" [chat_system_name]] "$pretty_name"]

<hr>
"

set formhtml "
<form method=post action=post-personal-message>
<table><tr><td valign=top align=right>
Chat:</td><td> <textarea wrap name=msg rows=2 cols=30></textarea>
[export_form_scope_vars chatter_id]
</td><td valign=top> <a href=message?[export_url_scope_vars chatter_id]>See new messages without posting</a><br>
<a href=index?[export_url_scope_vars]>Exit this room</a>
</td>
</tr>
<tr><td></td><td><input type=submit value=\"Send message\"></td></tr></table>
</form>
"

if {[ad_parameter MostRecentOnTopP chat]} {
    append page_content $formhtml
    set formhtml ""
}

set chat_rows [chat_get_personal_posts $chatter_id]

append page_content "

<ul>
$chat_rows
</ul>
$formhtml
</ul>

<a href=\"javascript:helpWindow('js-message?[export_url_scope_vars chatter_id]')\">Open javascript version of this room</a>

</ul>

[ad_scope_footer]
"


doc_return  200 text/html $page_content


