# /www/chat/invite.tcl
ad_page_contract {
    This page send an e-mail invites buddies to the chat room
    <b>Note:<b> If the page is accessed through /groups pages then group_id and group_vars_set are already set up in the environment by the ug_serve_section.<br>
    group_vars_set contains group related variables (group_id, group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @param email e-mail address of the person you want to invite
    @param chat_room_id invite to this room id
    @param return_url
    @param scope
    @param owner_id note that owner_id is the user_id of the user who owns this module (when scope=user)
    @param group_id
    @param on_which_group
    @param on_what_id

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @creation-date 18 November 1998
    @cvs-id invite.tcl,v 3.2.6.6 2000/07/21 19:50:41 psu Exp
} {
    email
    chat_room_id:naturalnum,notnull
    return_url:optional
    scope:optional
    owner_id:optional,naturalnum
    group_id:optional,naturalnum
    on_which_group:optional,naturalnum
    on_what_id:optional,naturalnum

}

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

if ![philg_email_valid_p $email] {
    ad_scope_return_complaint 1 "<li>What you entered (\"<tt>$email</tt>\") doesn't look like a valid email address to us.
  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
    return
}

set from_email [db_string chat_invite_set_from_email {
    select email from users where user_id=:user_id}]
set from_name [db_string chat_invite_set_from_name {
    select first_names||' '||last_name as whole_name from users where user_id=:user_id}]

set chat_room_name [db_string chat_invite_set_chat_room_name {select pretty_name from chat_rooms where chat_room_id=:chat_room_id}]

set subject "You are invited to join \"$chat_room_name\""

set message "

Please join me in the chat room \"$chat_room_name\":

[ad_parameter SystemURL]/chat/enter-room.tcl?[export_url_scope_vars]&chat_room_id=$chat_room_id

Hope to see you there!

-- $from_name
"

ns_sendmail $email $from_email $subject $message

if { ![exists_and_not_null return_url] } {
    set return_url "chat"
}
db_release_unused_handles
ad_returnredirect "$return_url?[export_url_scope_vars chat_room_id]"
