# /webmail/message-send-3.tcl
# by jsc@arsdigita.com (2000-03-01)

# Send the email.

ad_page_variables {{response_to_msg_id ""} outgoing_msg_id}


set user_id [ad_verify_and_get_user_id]
set db [ns_db gethandle]

validate_integer outgoing_msg_id $outgoing_msg_id
set author_id [database_to_tcl_string_or_null $db "select creation_user
from wm_outgoing_messages
where outgoing_msg_id = $outgoing_msg_id"]

if { $author_id == "" } {
    ad_return_error "No Such Message" "The specified message does not exist. You may already have sent it,
or waited too long to send it."
    return
} elseif { $author_id != $user_id } {
    ad_return_error "Permission Denied" "You do not have permission to send this message."
    return
}

with_transaction $db {
    ns_db dml $db "begin wm_compose_message($outgoing_msg_id); end;"
    set from [database_to_tcl_string $db "select value
from wm_outgoing_headers
where name = 'From'
and outgoing_msg_id = $outgoing_msg_id"]
    set composed_message [database_to_tcl_string $db "select composed_message
from wm_outgoing_messages
where outgoing_msg_id = $outgoing_msg_id"]

    regsub -all "\r" $composed_message "" cleaned_message

    qmail_send_complete_message $from $cleaned_message
    ns_db dml $db "delete from wm_outgoing_messages where outgoing_msg_id = $outgoing_msg_id"
} {
    ad_return_error "Database Error" "An error occured while we attempted to compose your message:
<pre>
$errmsg
</pre>"
    return
}

if { ![empty_string_p $response_to_msg_id] } {
    ad_returnredirect "message.tcl?msg_id=$response_to_msg_id"
} else {
    ad_returnredirect "index.tcl"
}


