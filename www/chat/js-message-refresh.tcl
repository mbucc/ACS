# /www/chat/js-message-refresh.tcl
ad_page_contract {
    Refresh messages

    Note: if page is accessed through /groups pages then group_id and group_vars_set
    are already set up in the environment by the ug_serve_section. group_vars_set
    contains group related variables (group_id, group_name, group_short_name,
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chatter_id
    @param scope
    @param owner
    @param group_id
    @param on_which_group
    @param on_what_id
    @creation-date 11/18/1998
    @cvs-id js-message-refresh.tcl,v 3.1.2.5 2000/09/22 01:37:12 kevin Exp

} {
    {chatter_id:notnull,naturalnum}
    {scope:optional}
    {owner_id:optional}
    {group_id:optional}
    {on_which_group:optional}
    {on_what_id:optional}
}

# chatter_id
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

ad_scope_authorize $scope registered group_member none

set time_user_id [chat_last_personal_post $chatter_id]
set last_time [lindex $time_user_id 0]
set last_poster [lindex $time_user_id 1]

set page_content "
<meta http-equiv=\"Refresh\" content=\"[ad_parameter CacheTimeout chat]\">
<script language=javascript>
var newest_poster='$last_poster'
var newest_time='$last_time'
function load_new () {
    if(newest_time!=top.chat_rows.last_time || newest_poster!=top.chat_rows.last_poster) top.frames\[1\].location = 'js-message-chat-rows.tcl?[export_url_scope_vars chatter_id]';
}
</script>
<body bgcolor=white onLoad=\"load_new()\">
"


doc_return  200 text/html $page_content






