# /webmail/message-send-add-attachment.tcl

ad_page_contract {
    Attach file to outgoing message.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-03-01
    @cvs-id message-send-add-attachment.tcl,v 1.4.2.5 2000/09/20 00:14:59 jsc Exp
} {
    upload_file
    outgoing_msg_id:integer
    { response_to_msg_id:integer "" }
}

set user_id [ad_verify_and_get_user_id]

# Check permissions.

set creation_user [db_string author "select creation_user
from wm_outgoing_messages
where outgoing_msg_id = :outgoing_msg_id" -default ""]

if { $creation_user == "" } {
    ad_return_error "No Such Message" "The message you are attempting to attach a file to is no longer valid."
    return
} elseif { $creation_user != $user_id } {
    ad_return_error "Permission Denied" "You do not have permission to attach a file to this message."
    return
}

if { [empty_string_p $upload_file] } {
    ad_return_error "No File Selected" "You must specify a file to attach."
    return
}

set tmp_filename [ns_queryget upload_file.tmpfile]
set content_type [ns_guesstype $upload_file]

if { [empty_string_p $content_type] } {
    set content_type "application/octet-stream"
}

db_with_handle db {
    ns_ora blob_dml_file $db "insert into wm_outgoing_message_parts (outgoing_msg_id, data, filename, content_type, sort_order)
values ($outgoing_msg_id, empty_blob(), '[file tail $upload_file]', '$content_type', wm_outgoing_parts_sequence.nextval)
returning data into :1" $tmp_filename
}

ad_returnredirect "message-send-2?[export_url_vars outgoing_msg_id response_to_msg_id]"



