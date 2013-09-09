# /webmail/message-refile.tcl

ad_page_contract {
    Refile a single message and display next unread, undeleted message
    or index if none exist.

    @param msg_id The ID of the msg we're re-filing
    @param mailbox_id The ID of the mailbox to which we're re-filing 
    the message. If this parameter is unspecified (e.g. empty_string) 
    we return a nice error telling the user to first pick a mailbox

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id message-refile.tcl,v 1.6.2.4 2000/07/26 17:21:38 mbryzek Exp
} {
    msg_id:integer
    { mailbox_id:integer "" }
}


set user_id [ad_verify_and_get_user_id]

if { [empty_string_p $mailbox_id] } {
    ad_return_complaint 1 "<li>You have to select a folder to which to refile this message."
    return
}


with_catch errmsg {
    db_dml refile_msg "update wm_message_mailbox_map
set mailbox_id = :mailbox_id
 where msg_id = :msg_id
  and mailbox_id in (select mailbox_id from wm_mailboxes where creation_user = :user_id)"
} {
    ad_return_error "Refiling Failed" "Deletion of messages failed:
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

# Skip to next unseen, undeleted message, or back to the folder if no such message.
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
