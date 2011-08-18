# $Id: invite.tcl,v 3.0.4.1 2000/04/28 15:09:51 carsten Exp $
# File:     /chat/invite.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com, philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  invites buddies to the chat room

# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#       are already set up in the environment by the ug_serve_section. group_vars_set 
#       contains group related variables (group_id, group_name, group_short_name, 
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables

# email, chat_room_id
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]

if ![philg_email_valid_p $email] {
    ad_scope_return_complaint 1 "<li>What you entered (\"<tt>$email</tt>\") doesn't look like a valid email address to us.
  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
" $db
    return
}

set from_email [database_to_tcl_string $db "select email from users where user_id=$user_id"]
set from_name [database_to_tcl_string $db "select first_names||' '||last_name as whole_name from users where user_id=$user_id"]

set chat_room_name [database_to_tcl_string $db "select pretty_name from chat_rooms where chat_room_id=$chat_room_id"]

set subject "You are invited to join \"$chat_room_name\""

set message "

Please join me in the chat room \"$chat_room_name\":

[ad_parameter SystemURL]/chat/enter-room.tcl?[export_url_scope_vars]&chat_room_id=$chat_room_id

Hope to see you there!

-- $from_name
"

ns_sendmail $email $from_email $subject $message

ad_returnredirect "chat.tcl?[export_url_scope_vars chat_room_id]"
