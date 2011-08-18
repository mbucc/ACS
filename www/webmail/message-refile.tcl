# /webmail/message-refile.tcl
# by jsc@arsdigita.com (2000-02-23)

# Refile a single message and display next unread, undeleted message
# or index if none exist.

ad_page_variables {msg_id mailbox_id}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

validate_integer msg_id $msg_id
validate_integer mailbox_id $mailbox_id

with_catch errmsg {
    ns_db dml $db "update wm_message_user_map
set mailbox_id = $mailbox_id
 where msg_id = $msg_id
  and mailbox_id in (select mailbox_id from wm_mailboxes where creation_user = $user_id)"
} {
    ad_return_error "Deletion Failed" "Deletion of messages failed:
<pre>
$errmsg
</pre>
"
    return
}


# Figure out where we're supposed to go from here.
set current_messages [ad_get_client_property "webmail" "current_messages"]

set go_to_next_message_p 0

# Skip to next unseen, undeleted message, or back to the folder if no such message.
foreach message $current_messages {
    set current_msg_id [lindex $message 0]
    set seen_p [lindex $message 1]
    set deleted_p [lindex $message 2]

    if { $msg_id == $current_msg_id } {
	set go_to_next_message_p 1
	continue
    }

    if { $go_to_next_message_p && $seen_p == "f" && $deleted_p == "f" } {
	ad_returnredirect "message.tcl?msg_id=$current_msg_id"
	return
    }
}

ad_returnredirect "index.tcl"
