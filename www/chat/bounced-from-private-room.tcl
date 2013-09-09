# /www/chat/bounced-from-private-room.tcl
ad_page_contract {
    This page explains to user why he was bounced and links him over to the group user page if he wants to apply for membership.

    <b>Note:<b> If the page is accessed through /groups pages then group_id and group_vars_set are already set up in the environment by the ug_serve_section.<br>
    group_vars_set contains group related variables (group_id, group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chat_room_id
    @param scope
    @param owner_id note that owner_id is the user_id of the user who owns this module (when scope=user)
    @param group_id
    @param on_which_group
    @param on_what_id
    @creation-date 18 November 1998
    @cvs-id bounced-from-private-room.tcl,v 3.1.6.7 2000/09/22 01:37:07 kevin Exp
} {
    chat_room_id:naturalnum,notnull
    scope:optional
    owner_id:optional,naturalnum
    group_id:optional,naturalnum
    on_which_group:optional,naturalnum
    on_what_id:optional,naturalnum

}

ad_scope_error_check

ad_scope_authorize $scope registered group_member none

set selection [db_0or1row chat_get_general_info {
select cr.pretty_name, cr.group_id as private_group_id, ug.group_name
from chat_rooms cr , user_groups ug
where cr.chat_room_id = :chat_room_id
and cr.group_id = ug.group_id}]

if {$selection == 0} {
    ad_return_complaint "Could not find room" "Could not find chat room with id $chat_room_id"
    db_release_unused_handles
    return
}

set page_content "

[ad_scope_header "Private Room"]
[ad_scope_page_title "Private Room"]
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [chat_system_name]] "Private Room"]

<hr>

The chat room \"$pretty_name\" is private.  You have to be a member of
<a href=\"/ug/group?[export_url_scope_vars]&group_id=$private_group_id\">$group_name</a>
to participate.


[ad_scope_footer]
"



doc_return  200 text/html $page_content
