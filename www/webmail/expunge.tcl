# /webmail/expunge.tcl
# by jsc@arsdigita.com (2000-02-23)

# Delete all messages and associated rows from various tables that have been
# marked for deletion in a single mailbox.

ad_page_variables mailbox_id

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

if { [database_to_tcl_string $db "select count(*)
from wm_mailboxes
where mailbox_id = $mailbox_id
  and creation_user = $user_id"] == 0 } {
    ad_return_error "Permission Denied" "You do not have permission to expunge this folder."
    ns_log Notice "WEBMAIL WARNING: user $user_id attempted to expunge mailbox $mailbox_id"
    return
}

set msg_ids_to_delete [database_to_tcl_list $db "select msg_id
from wm_message_user_map
where mailbox_id = $mailbox_id
and deleted_p = 't'"]

with_transaction $db {
    foreach msg_id $msg_ids_to_delete {
	# A delete trigger will delete rows from other tables that reference this one.
	ns_db dml $db "delete from wm_messages where msg_id = $msg_id"
    }
} {
    ad_return_error "Expunge Failed" "Unable to delete message:
<pre>
$errmsg
</pre>
"
    return
}

ad_returnredirect "index.tcl?[export_url_vars mailbox_id]"
