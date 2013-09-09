# /www/chat/js-message-chat-rows.tcl

ad_page_contract {

    If page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chatter_id
    @param scope
    @param owner_id
    @param group_id
    @param on_what_id
    @creation-date 1998-11-18
    @cvs-id js-message-chat-rows.tcl,v 3.0.12.6 2000/09/22 01:37:12 kevin Exp

} {
    {chatter_id:naturalnum,notnull}
    {scope ""}
    {owner_id:naturalnum,optional}
    {group_id:naturalnum,optional}
    {on_what_id:naturalnum,optional}
}

ad_scope_error_check

ad_scope_authorize $scope registered group_member none

set time_user_id [chat_last_personal_post $chatter_id]
set last_time [lindex $time_user_id 0]
set last_poster [lindex $time_user_id 1]

set page_content "
<script>
var last_time='$last_time';
var last_poster='$last_poster';
</script>
<body bgcolor=white>
"

if {[ad_parameter MostRecentOnTopP chat]} {
    append page_content "
    <a name=most_recent></a>
    "
}

append page_content "
[chat_get_personal_posts $chatter_id]
"

if {![ad_parameter MostRecentOnTopP chat]} {
    append page_content "
    <a name=most_recent></a>
    "
}

doc_return  200 text/html $page_content






