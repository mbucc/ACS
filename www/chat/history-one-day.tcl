# $Id: history-one-day.tcl,v 3.0.4.1 2000/04/28 15:09:50 carsten Exp $
# File:     /chat/history-one-day.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com

# we don't memoize a single day of chat history; we assume that not
# too many folks are interested in any given day for a particular chat
# room

set_the_usual_form_variables

# chat_room_id, the_date 
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]

set private_group_id [chat_room_group_id $chat_room_id]

if { ![empty_string_p $private_group_id] && ![ad_user_group_member_cache $private_group_id $user_id]} {
    ad_returnredirect "bounced-from-private-room.tcl?[export_url_scope_vars chat_room_id]"
    return
}

set selection [ns_db 0or1row $db "select pretty_name
from chat_rooms
where chat_room_id = $chat_room_id"]

if { $selection == "" } {
    ad_scope_return_error "Room deleted" "We couldn't find the chat room you tried to enter. It was probably deleted by the site administrator." $db
    return
}

set_variables_after_query

set selection [ns_db select $db "select to_char(creation_date, 'HH24:MI:SS') as time, nvl(msg_bowdlerized, msg) as filtered_msg, first_names, last_name, creation_user
from chat_msgs, users
where chat_msgs.creation_user = users.user_id
and chat_room_id = $chat_room_id
and chat_msgs.approved_p = 't'
and trunc(creation_date) = '$the_date'
and system_note_p <> 't'
order by creation_date"]

set items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query 
    set filtered_msg [ns_quotehtml $filtered_msg]
    append items "<a target=newwindow href=\"/shared/community-member.tcl?[export_url_scope_vars]&user_id=$creation_user\">$first_names $last_name</a> ($time) $filtered_msg<br>\n"
}

ns_return 200 text/html "

[ad_scope_header "[util_AnsiDatetoPrettyDate $the_date]: $pretty_name" $db]
[ad_scope_page_title [util_AnsiDatetoPrettyDate $the_date] $db]
[ad_scope_context_bar_ws_or_index [list "index.tcl?[export_url_scope_vars]" [chat_system_name]] [list "chat.tcl?[export_url_scope_vars chat_room_id]" "One Room"] [list "history.tcl?[export_url_scope_vars chat_room_id]" "History"] "One Day"]

<hr>

$pretty_name on [util_AnsiDatetoPrettyDate $the_date]:

<ul>

$items

</ul>

[ad_scope_footer]
"
