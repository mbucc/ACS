# admin/chat/msgs-for-user.tcl

ad_page_contract {

    Find messages post by this user.

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param user_id find messages post by this user
    @creation-date  1998-11-18
    @cvs-id $Id: msgs-for-user.tcl,v 1.2.2.1 2000/02/03 09:20:24 ron Exp
} {
    user_id:naturalnum,notnull
}

ad_maybe_redirect_for_registration

db_1row chat_admin_chat_msgs_get_user_name {
    select first_names || ' ' || last_name as username
    from users where user_id = :user_id}

set sql_query {select cr.pretty_name, cm.msg, u.first_names || ' ' || u.last_name as recipient
from chat_rooms cr, chat_msgs cm, users u
where creation_user = :user_id
and cm.chat_room_id = cr.chat_room_id(+)
and cm.recipient_user = u.user_id(+)
and cm.system_note_p = 'f'
order by cr.pretty_name, u.first_names, u.last_name, cm.creation_date}

set msgs ""
set last_chat_room ""
set last_recipient " "

db_foreach chat_admin_for_user_list_of_names $sql_query {
    
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

set page_content "[ad_admin_header "Messages By $username"]

<h2>Messages By $username</h2>

[ad_admin_context_bar [list "index.tcl" "Chat System"] "Messages By $username"]

<hr>

<ul>
$msgs
</ul>

[ad_admin_footer]
"



doc_return  200 text/html $page_content