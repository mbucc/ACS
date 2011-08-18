# $Id: canned-response-edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:37 carsten Exp $
set_the_usual_form_variables
# response_id, one_line, response_text

set db [ns_db gethandle]

ns_db dml $db "update ec_canned_responses
set one_line = '$QQone_line', response_text = '$QQresponse_text'
where response_id = $response_id"

ad_returnredirect "canned-responses.tcl"