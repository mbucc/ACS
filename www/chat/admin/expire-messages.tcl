# expire-messages.tcl,v 1.2.2.1 2000/02/03 09:20:21 ron Exp
# File:     admin/chat/expire-messages.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  expires messages of a chat room

set_the_usual_form_variables

# chat_room_id

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set expiration_days [database_to_tcl_string $db "select expiration_days from chat_rooms where chat_room_id=$chat_room_id"]

if {[empty_string_p $expiration_days]} {
    ad_return_complaint 1 "You haven't set expiration_days so we
couldn't possibly delete any messages"
    return
}

ns_db dml $db "delete from chat_msgs 
where chat_room_id = $chat_room_id
and creation_date < sysdate-$expiration_days"

set n_rows_deleted [ns_ora resultrows $db]

ns_return 200 text/html "[ad_admin_header "$n_rows_deleted rows were deleted"]

<h2>$n_rows_deleted rows deleted</h2>

[ad_admin_context_bar [list "index.tcl" Chat] [list "one-room.tcl?[export_url_vars chat_room_id]" "One Room"] "Deleted Expired Messages"]

<hr>

[ad_admin_footer]
"



