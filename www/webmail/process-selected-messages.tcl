# /webmail/process-selected-messages.tcl
# by jsc@arsdigita.com (2000-02-23)

# Delete or refile messages selected messages.

ad_page_variables {{msg_ids -multiple-list} action mailbox_id}

if { $msg_ids == "" } {
    # nothing selected
    ad_returnredirect "index.tcl"
    return
}

if { ![regexp {^[{} 0-9]+$} $msg_ids] } {
    ad_return_complaint 1 "<li>Please don't try to hack the system."
    return
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

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
		ns_db dml $db "update wm_message_user_map
set deleted_p = '$deleted_p_value'
 where msg_id in ([join $msg_id_chunk ", "])
  and mailbox_id in (select mailbox_id from wm_mailboxes where creation_user = $user_id)"
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
	    ad_returnredirect "folder-create.tcl?target=[ns_urlencode "refile-selected.tcl"]"
	    return
	} else {
	    validate_integer mailbox_id $mailbox_id
	    ad_returnredirect "refile-selected.tcl?[export_url_vars mailbox_id]"
	    return
	}
    }
}

ad_returnredirect "index.tcl"


