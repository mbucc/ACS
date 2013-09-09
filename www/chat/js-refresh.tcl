# /chat/js-referesh.tcl

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
    @param on_which_group
    @param on_what_id
    @creation-date 1998-11-18
    @cvs-id  js-refresh.tcl,v 3.1.2.5 2000/09/22 01:37:13 kevin Exp
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

set page_content ""
set last_post_id [chat_last_post $chat_room_id]

append page_content "
<meta http-equiv=\"Refresh\" content=\"[ad_parameter JavaScriptRefreshInterval chat 5]\">
<script language=javascript>
var newest_post=$last_post_id;

function load_new () {
    if (newest_post != top.chat_rows.last_post) top.chat_rows.location = 'js-chat-rows.tcl?[export_url_scope_vars chat_room_id]&random=$last_post_id';
}
</script>
<body bgcolor=white onLoad=\"load_new()\">
"


doc_return  200 text/html $page_content


