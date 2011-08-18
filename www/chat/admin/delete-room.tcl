# delete-room.tcl,v 1.2.2.1 2000/02/03 09:20:19 ron Exp
# File:     admin/chat/delete-room.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  deletes a chat room

set_the_usual_form_variables

# chat_room_id 

set db [ns_db gethandle]

set user_id [ad_scope_authorize $db $scope admin group_admin none]
set selection [ns_db 0or1row $db "select * from chat_rooms where chat_room_id = $chat_room_id"]

if { $selection == "" } {
    ad_return_error "Not Found" "Could not find chat_room $chat_room_id"
    return
}

set_variables_after_query

ReturnHeaders 

ns_write "
[ad_scope_admin_header "Confirm deletion of $pretty_name" $db]
[ad_scope_admin_page_title $pretty_name $db]
[ad_scope_admin_context_bar [list "index.tcl" Chat] [list "one-room.tcl?[export_url_vars chat_room_id]" "One Room"] "Confirm Deletion"]

<hr>

Are you sure that you want to delete $pretty_name (and its 
[database_to_tcl_string $db "select count(*) from chat_msgs where chat_room_id = $chat_room_id"] messages)?

<p>

<center>
<form method=GET action=\"delete-room-2.tcl\">
[export_form_scope_vars chat_room_id]
<input type=submit value=\"Yes, I'm sure\">
</form>
</center>


[ad_scope_admin_footer]
"
