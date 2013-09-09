# www/admin/chat/index.tcl
ad_page_contract {
    Admin for chat, main page. List all available chat rooms.

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @creation-date 18 November 1999
    @cvs-id index.tcl,v 3.2.2.6 2000/09/22 01:34:29 kevin Exp
} {

}

set title "Chat System"

append page_content "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar $title]

<hr>

Documentation:  <a href=\"/doc/chat\">/doc/chat.html</a>
<br>
User pages:  <a href=\"/chat/\">/chat/</a>

<ul>
<h4>Active chat rooms</h4>
"

set count 0
set inactive_title_shown_p 0
set room_items ""


db_foreach admin_chat_index_chat_room_info {
    select chat_rooms.chat_room_id, 
        chat_rooms.pretty_name, 
        chat_rooms.active_p, 
        count(chat_msg_id) as n_messages, 
        max(chat_msgs.creation_date) as most_recent_date
    from chat_rooms, chat_msgs
    where chat_rooms.chat_room_id = chat_msgs.chat_room_id(+)
    group by chat_rooms.chat_room_id, chat_rooms.pretty_name, chat_rooms.active_p
    order by chat_rooms.active_p desc, upper(chat_rooms.pretty_name)} {

 
    if { $active_p == "f" } {
	if { $inactive_title_shown_p == 0 } {
	    # We have not shown the inactive title yet.
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

<p>

<a href=create-room>Create a new room</a>
</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_content