# $Id: msgs-for-user.tcl,v 3.0 2000/02/06 03:10:10 ron Exp $
# File:     admin/chat/msgs-for-user.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com

set_the_usual_form_variables
# user_id

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set selection [ns_db 1row $db "select first_names || ' ' || last_name as username
from users
where user_id = $user_id"]

set_variables_after_query

set selection [ns_db select $db "select cr.pretty_name, cm.msg, u.first_names || ' ' || u.last_name as recipient
from chat_rooms cr, chat_msgs cm, users u
where creation_user = $user_id
and cm.chat_room_id = cr.chat_room_id(+)
and cm.recipient_user = u.user_id(+)
and cm.system_note_p = 'f'
order by cr.pretty_name, u.first_names, u.last_name, cm.creation_date"]

set msgs ""
set last_chat_room ""
set last_recipient " "

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    
    if { ![empty_string_p $pretty_name] && $last_chat_room != $pretty_name } {
	append msgs "<h4>Messages in $pretty_name room</h4>\n"
	set last_chat_room $pretty_name
    }
    if { ![empty_string_p $recipient] && $recipient != $last_recipient } {
	append msgs "<h4>Messages to $recipient</h4>\n"
	set last_recipient $recipient
    }
    
    append msgs "<li>$msg\n"
}

ns_return 200 text/html "[ad_admin_header "Messages By $username"]

<h2>Messages By $username</h2>

[ad_admin_context_bar [list "index.tcl" "Chat System"] "Messages By $username"]

<hr>

<ul>
$msgs
</ul>

[ad_admin_footer]
"
