ad_page_contract {
    The main index page for administration of chat

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param scope is this room "public", "user", or "group"
    @param group_id group this room belong to if scope = "group"
    @creation-date 18 November 1998
    @cvs-id index.tcl,v 1.5.2.8 2000/09/22 01:37:14 kevin Exp
} {
    {scope:optional}
    {group_id:optional,naturalnum}
}

# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check

set local_user_id [ad_scope_authorize $scope admin group_admin none]

set title "Chat System"

set page_content "
[ad_scope_admin_header $title]
[ad_scope_admin_page_title $title]
[ad_scope_admin_context_bar $title]

<hr>

<ul>
<h4>Active chat rooms</h4>
"

# only filter by group if the scope is set accordingly
if {$scope=="group"} {

    set where_group "
	and chat_rooms.group_id = :group_id
	and scope = 'group'"
} else {
    set where_group ""
    set bind_vars ""
}


set query "
  select chat_rooms.chat_room_id, chat_rooms.pretty_name, chat_rooms.active_p, 
    count(chat_msg_id) as n_messages, max(chat_msgs.creation_date) as most_recent_date
  from chat_rooms, chat_msgs
  where chat_rooms.chat_room_id = chat_msgs.chat_room_id(+)  $where_group
  group by chat_rooms.chat_room_id, chat_rooms.pretty_name, chat_rooms.active_p
  order by chat_rooms.active_p desc, upper(chat_rooms.pretty_name)"

set count 0
set inactive_title_shown_p 0
set room_items ""

db_foreach chat_admin_index_get_rooms $query {
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
	
    append room_items "<li><a href=\"one-room?[export_url_vars chat_room_id]\">$pretty_name</a>\n"
    if { $n_messages == 0 } {
	append room_items " (no messages)\n"
    } else {
	append room_items " ($n_messages; most recent on $most_recent_date)\n"
    }
    incr count
}

append page_content "
$room_items

<p><a href=create-room>Create a new room</a>

</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_content
