# delete-messages-2.tcl,v 1.1.2.3 2000/02/03 09:20:16 ron Exp
# File:     admin/chat/delete-messages-2.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  deletes messages of a chat room

set_the_usual_form_variables

# chat_room_id

ad_maybe_redirect_for_registration

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope admin group_admin none]
ns_db dml $db "delete from chat_msgs where chat_room_id=$chat_room_id"

ad_returnredirect "one-room.tcl?[export_url_scope_vars chat_room_id]"
