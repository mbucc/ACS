# /webmail/message-send-3.tcl

ad_page_contract {
    Send the email.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-03-01
    @cvs-id message-send-3.tcl,v 1.4.2.5 2001/01/12 00:25:06 khy Exp
} {
    { response_to_msg_id:integer "" }
    outgoing_msg_id:naturalnum,notnull,verify
}


set user_id [ad_verify_and_get_user_id]

set author_id [db_string author "select creation_user
from wm_outgoing_messages
where outgoing_msg_id = :outgoing_msg_id" -default ""]

if { $author_id == "" } {
    ad_return_error "No Such Message" "The specified message does not exist. You may already have sent it,
or waited too long to send it."
    return
} elseif { $author_id != $user_id } {
    ad_return_error "Permission Denied" "You do not have permission to send this message."
    return
}

db_transaction {
    db_dml compose_message "begin wm_compose_message(:outgoing_msg_id); end;"
    set from [db_string from_value "select value
from wm_outgoing_headers
where name = 'From'
and outgoing_msg_id = :outgoing_msg_id"]
    set composed_message [db_string message "select composed_message
from wm_outgoing_messages
where outgoing_msg_id = :outgoing_msg_id"]

    regsub -all "\r" $composed_message "" cleaned_message

    qmail_send_complete_message $from $cleaned_message
    db_dml delete_msg "delete from wm_outgoing_messages where outgoing_msg_id = :outgoing_msg_id"
} on_error {
    ad_return_error "Database Error" "An error occured while we attempted to compose your message:
<pre>
$errmsg
</pre>"
    return
}

if { ![empty_string_p $response_to_msg_id] } {
    ad_returnredirect "message?msg_id=$response_to_msg_id"
} else {
    ad_returnredirect "index"
}


