# /webmail/message-send-add-attachment.tcl
# by jsc@arsdigita.com (2000-03-01)

# Attach file to outgoing message.

ad_page_variables {upload_file outgoing_msg_id {response_to_msg_id ""}}

set user_id [ad_verify_and_get_user_id]
set db [ns_db gethandle]


# Check permissions.
validate_integer outgoing_msg_id $outgoing_msg_id

set creation_user [database_to_tcl_string_or_null $db "select creation_user
from wm_outgoing_messages
where outgoing_msg_id = $outgoing_msg_id"]

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

ns_ora blob_dml_file $db "insert into wm_outgoing_message_parts (outgoing_msg_id, data, filename, content_type, sort_order)
values ($outgoing_msg_id, empty_blob(), '[file tail $QQupload_file]', '$content_type', wm_outgoing_parts_sequence.nextval)
returning data into :1" $tmp_filename

ad_returnredirect "message-send-2.tcl?[export_url_vars outgoing_msg_id response_to_msg_id]"



