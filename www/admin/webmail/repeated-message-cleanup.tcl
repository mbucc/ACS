# /admin/webmail/repeated-message-cleanup.tcl

ad_page_contract {
    Delete all but one repeated message per recipient.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-04-03
    @cvs-id repeated-message-cleanup.tcl,v 1.3.6.2 2000/07/21 03:58:33 ron Exp
} {
    message_id
}

db_foreach user_mailboxes {
    select distinct mailbox_id
    from wm_messages m, wm_message_mailbox_map
    where m.msg_id = mum.msg_id
    and message_id = :message_id
} {
    db_dml delete_message {
	delete from wm_messages
	where message_id = :message_id
	and msg_id <> (select min(m.msg_id)
		       from wm_messages m, wm_message_mailbox_map mmm
		       where m.msg_id = mmm.msg_id
		       and message_id = :message_id
		       and mmm.mailbox_id = :mailbox_id)
    }
}

ad_returnredirect "problems.tcl"