# index.tcl,v 1.2.2.1 2000/02/03 09:20:23 ron Exp
# File:     admin/chat/index.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  admin chat main page


set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check

set db [ns_db gethandle]
set local_user_id [ad_scope_authorize $db $scope admin group_admin none]


ReturnHeaders

set title "Chat System"

ns_write "
[ad_scope_admin_header $title $db]
[ad_scope_admin_page_title $title $db]
[ad_scope_admin_context_bar $title]

<hr>

<ul>
<h4>Active chat rooms</h4>
"


# only filter by group if the scope is set accordingly
if {$scope=="group"} {
    set where_group "
	and chat_rooms.group_id = $group_id
	and scope = 'group'"
} else {
    set where_group ""
}

set selection [ns_db select $db "
  select chat_rooms.chat_room_id, chat_rooms.pretty_name, chat_rooms.active_p, 
    count(chat_msg_id) as n_messages, max(chat_msgs.creation_date) as most_recent_date
  from chat_rooms, chat_msgs
  where chat_rooms.chat_room_id = chat_msgs.chat_room_id(+)  $where_group
  group by chat_rooms.chat_room_id, chat_rooms.pretty_name, chat_rooms.active_p
  order by chat_rooms.active_p desc, upper(chat_rooms.pretty_name)"]


set count 0
set inactive_title_shown_p 0
set room_items ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $active_p == "f" } {
	if { $inactive_title_shown_p == 0 } {
	    # we have not shown the inactive title yet
	    if { $count == 0 } {
		append room_items "<li>No active chat rooms"
	    }
	    set inactive_title_shown_p 1
	    append room_items "<h4>Inactive chat rooms</h4>"
	}
    }
	
    append room_items "<li><a href=\"one-room.tcl?[export_url_vars chat_room_id]\">$pretty_name</a>\n"
    if { $n_messages == 0 } {
	append room_items " (no messages)\n"
    } else {
	append room_items " ($n_messages; most recent on $most_recent_date)\n"
    }
    incr count
}


ns_write "
$room_items

<p><a href=create-room.tcl>Create a new room</a>

</ul>

[ad_admin_footer]
"
