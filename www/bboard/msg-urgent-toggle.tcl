# $Id: msg-urgent-toggle.tcl,v 3.0.4.1 2000/04/28 15:09:42 carsten Exp $
set_the_usual_form_variables

# msg_id, return_url

set user_id [ad_verify_and_get_user_id]
set db [ns_db gethandle]

ns_db dml $db "update bboard set urgent_p = logical_negation(urgent_p) where
msg_id = '$msg_id'  and bboard.user_id = $user_id"

ad_returnredirect $return_url
