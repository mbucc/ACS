# $Id: canned-response-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:37 carsten Exp $
set_form_variables

# response_id

set db [ns_db gethandle]

ns_db dml $db "delete from ec_canned_responses where response_id = $response_id"

ad_returnredirect "canned-responses.tcl"