# /webmail/expunge.tcl

ad_page_contract {
    Delete all messages and associated rows from various tables that have been
    marked for deletion in a single mailbox.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id expunge.tcl,v 1.4.6.4 2000/08/13 20:04:25 mbryzek Exp
} {
    mailbox_id:integer
}

set user_id [ad_verify_and_get_user_id]

if { [db_string mbox_count "select count(*)
from wm_mailboxes
where mailbox_id = $mailbox_id
  and creation_user = $user_id"] == 0 } {
    ad_return_error "Permission Denied" "You do not have permission to expunge this folder."
    ns_log Notice "WEBMAIL WARNING: user $user_id attempted to expunge mailbox $mailbox_id"
    return
}

with_catch errmsg {
    db_dml msg_delete "delete from wm_messages
 where msg_id in (select msg_id from wm_message_mailbox_map
                 where mailbox_id = :mailbox_id
                 and deleted_p = 't')"
} {
    ad_return_error "Expunge Failed" "Unable to delete messages:
<pre>
$errmsg
</pre>
"
    return
}

ad_returnredirect "index?[export_url_vars mailbox_id]"
