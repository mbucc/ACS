# /webmail/refile-selected.tcl
# by jsc@arsdigita.com (2000-02-23)

# Perform bulk refiling of selected messages.

ad_page_variables {mailbox_id}

validate_integer mailbox_id $mailbox_id

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set msg_ids [ad_get_client_property "webmail" "selected_messages"]


if { [database_to_tcl_string $db "select count(*)
from wm_mailboxes
where mailbox_id = $mailbox_id
  and creation_user = $user_id"] == 0 } {
    ad_return_error "Permission Denied" "You do not have permission to refile to this mailbox."
    ns_log Notice "WEBMAIL WARNING: user $user_id attempted to refile messages to mailbox $mailbox_id"
    return
}

with_catch errmsg {
    # Oracle can only handle explicit sets of 1000 elements
    # at a time.
    set msg_id_start_index 0
    set msg_id_end_index 999
    while 1 {
	set msg_id_chunk [lrange $msg_ids $msg_id_start_index $msg_id_end_index]
	if { $msg_id_chunk == "" } {
	    break
	}
	incr msg_id_start_index 1000
	incr msg_id_end_index 1000
	ns_db dml $db "update wm_message_user_map
set mailbox_id = $mailbox_id
 where msg_id in ([join $msg_id_chunk ", "])
  and mailbox_id in (select mailbox_id from wm_mailboxes where creation_user = $user_id)"
    }
} {
    ad_return_error "Refiling Failed" "Refiling of messages failed:
<pre>
$errmsg
</pre>
"
    return
}

ad_returnredirect "index.tcl"

