# /webmail/message-delete.tcl

ad_page_contract {
    Delete a single message, move to next unread, undeleted message or
    back to index if none exist.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id message-delete.tcl,v 1.5.2.4 2000/08/13 20:04:25 mbryzek Exp
} {
    msg_id:integer
}

set user_id [ad_verify_and_get_user_id]

with_catch errmsg {
    db_dml delete_msg "update wm_message_mailbox_map
set deleted_p = 't'
 where msg_id = :msg_id
  and mailbox_id in (select mailbox_id from wm_mailboxes where creation_user = :user_id)"
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
set next_msg_id 0

# Skip to next unseen, undeleted message,
# next message if no next unseen message,
# or back to the folder if none of the above.

foreach message $current_messages {
    set current_msg_id [lindex $message 0]
    set seen_p [lindex $message 1]
    set deleted_p [lindex $message 2]

    if { $msg_id == $current_msg_id } {
	set go_to_next_message_p 1
	continue
    }

    if { $go_to_next_message_p } {
	if { $seen_p == "f" && $deleted_p == "f" } {
	    ad_returnredirect "message?msg_id=$current_msg_id"
	    return
	}

	if { $deleted_p == "f" && $next_msg_id == 0 } {
	    # Store msg_id of next read, undeleted message if we don't find any
	    # unread messages.
	    set next_msg_id $current_msg_id
	}
    }
}

if { $next_msg_id != 0 } {
    ad_returnredirect "message?msg_id=$next_msg_id"
} else {
    ad_returnredirect "index"
}
