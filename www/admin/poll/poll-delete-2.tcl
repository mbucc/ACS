# $Id: poll-delete-2.tcl,v 3.0.4.1 2000/04/28 15:09:15 carsten Exp $
# poll-delete-2.tcl -- remove a poll from the database, including votes

set_form_variables

# expects poll_id

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

ns_db dml $db "delete from poll_user_choices where poll_id = $poll_id"
ns_db dml $db "delete from poll_choices where poll_id = $poll_id"
ns_db dml $db "delete from polls where poll_id = $poll_id"

ns_db dml $db "end transaction"

ad_returnredirect index.tcl

