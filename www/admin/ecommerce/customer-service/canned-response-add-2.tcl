# $Id: canned-response-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:37 carsten Exp $
set_the_usual_form_variables
# one_line, response_text

set db [ns_db gethandle]

set existing_response_id [database_to_tcl_string_or_null $db "select response_id from ec_canned_responses where one_line = '$QQone_line'"]

if { ![empty_string_p $existing_response_id] } {
    ad_return_warning "Response Exists" "There already exists a canned response
with this description. You can <a href=\"canned-response-edit.tcl?response_id=$existing_response_id\">edit it</a> or go back and try again."
    return
}

ns_db dml $db "insert into ec_canned_responses (response_id, one_line, response_text)
values (ec_canned_response_id_sequence.nextval, '$QQone_line', '$QQresponse_text')"

ad_returnredirect "canned-responses.tcl"