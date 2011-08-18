# $Id: delete-messages-2.tcl,v 3.0.4.1 2000/04/28 15:08:29 carsten Exp $
# File:     admin/chat/delete-messages-2.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  deletes messages of a chat room

set_the_usual_form_variables

# chat_room_id

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

ns_db dml $db "delete from chat_msgs where chat_room_id=$chat_room_id"

ad_returnredirect "one-room.tcl?[export_url_vars chat_room_id]"
