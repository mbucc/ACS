# /webmail/process-selected-messages.tcl

ad_page_contract {
    Delete or refile messages selected messages.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id process-selected-messages.tcl,v 1.5.2.5 2000/08/13 20:04:26 mbryzek Exp
} {
    msg_ids:integer,optional,multiple
    action
    mailbox_id
    { return_url "index" }
}

if { ![exists_and_not_null msg_ids] } {
    # nothing selected
    ad_returnredirect "index"
    return
}

if { ![regexp {^[{} 0-9]+$} $msg_ids] } {
    ad_return_complaint 1 "<li>Please don't try to hack the system."
    return
}

set user_id [ad_verify_and_get_user_id]

switch -- $action {
    "Delete" -
    "Undelete" {
	if { $action == "Delete" } {
	    set deleted_p_value "t"
	} else {
	    set deleted_p_value "f"
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
		db_dml delete "update wm_message_mailbox_map
set deleted_p = '$deleted_p_value'
 where msg_id in ([join $msg_id_chunk ", "])
  and mailbox_id in (select mailbox_id from wm_mailboxes where creation_user = :user_id)"
	    }
	} {
	    ad_return_error "Deletion Failed" "Deletion of messages failed:
<pre>
$errmsg
</pre>
"
	    return
	}
    }
    "Refile" {
	# See if user owns destination mailbox.
	ad_set_client_property -persistent f "webmail" "selected_messages" $msg_ids
	if { $mailbox_id == "@NEW" } {
	    ad_returnredirect "folder-create?target=[ns_urlencode "refile-selected"]"
	    return
	} else {
	    validate_integer mailbox_id $mailbox_id
	    ad_returnredirect "refile-selected?[export_url_vars mailbox_id]"
	    return
	}
    }
}

ad_returnredirect $return_url


