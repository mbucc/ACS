proc wm_link_author { address } {
    return "<a href=\"filter-add.tcl?filter_type=author&filter_term=[ns_urlencode $address]\">[philg_quote_double_quotes $address]</a>"
}

proc wm_link_subject { subject } {
    # Leave "Re:" out of the filter.
    regexp {^(Re: *)?(.*)} $subject ignored ignored_prefix rest_of_subject
    return "<a href=\"filter-add.tcl?filter_type=subject&filter_term=[ns_urlencode $rest_of_subject]\">[philg_quote_double_quotes $subject]</a>"
}

proc wm_header_display {db msg_id header_display_style user_id} {
    if { $header_display_style == "short" } {
	set header_restriction_clause " and lower_name in ('to', 'from', 'cc', 'subject', 'date', 'in-response-to', 'references', 'reply-to')"
    } else {
	set header_restriction_clause ""
    }
    
    set header_fields [database_to_tcl_list_list $db "select lower_name, name, value
from wm_headers
where msg_id = $msg_id$header_restriction_clause
order by sort_order"]

    set results ""
    foreach field $header_fields {
	set lower_name [lindex $field 0]
	set name [lindex $field 1]
	set value [lindex $field 2]

	switch -- $lower_name {
	    "from" {
		append results "<b>$name</b>: <b>[wm_link_author $value]</b><br>\n"
	    }
	    "subject" {
		append results "<b>$name</b>: <b>[wm_link_subject $value]</b><br>\n"
	    }
	    "references" {
		append results "References: "

		set count 0
		while { [regexp {^\s*(<[^>]+>)\s*(.*)$} $value dummy message_id value] } {
		    incr count
		    set selection [ns_db select $db "select m.msg_id as ref_msg_id
from wm_messages m, wm_message_user_map mum, wm_mailboxes mbx
where message_id = '[DoubleApos $message_id]'
  and mbx.creation_user = $user_id
  and mbx.mailbox_id = mum.mailbox_id
  and mum.msg_id = m.msg_id"]

		    if { [ns_db getrow $db $selection] } {
			set_variables_after_query
			append results "<a href=\"message.tcl?msg_id=$ref_msg_id\">$count</a> "
			ns_db flush $db
		    } else { 
			append results "$count "
		    }
		}
		append results "<br>\n"
	    }
	    default {
		append results "[philg_quote_double_quotes "$name: $value"]<br>\n"
	    }
	}
    }
    return $results
}

# Quote text with "> " at the start of each line.
proc wm_quote_message { author msg_text } {
    if { ![empty_string_p $msg_text] } {
	regsub -all "\n" $msg_text "\n> " quoted_text
	return "$author wrote:
> $quoted_text"
    } else {
	return $msg_text
    }
}

proc wm_check_permissions { db msg_id user_id } {
    if { [database_to_tcl_string $db "select count(*) from wm_message_user_map mum, wm_mailboxes m
where mum.mailbox_id = m.mailbox_id
  and mum.msg_id = $msg_id
  and m.creation_user = $user_id"] == 0 } {
	return 0
    } else {
	return 1
    }
}

ns_register_proc GET /webmail/parts/* wm_get_mime_part

proc wm_get_mime_part { conn context } {
    set url_stub [ns_conn url]

    if { [regexp {/webmail/parts/([0-9]+)/(.*)} $url_stub match msg_id filename] } {
	set db [ns_db gethandle]
	set user_id [ad_verify_and_get_user_id]

	if { ![wm_check_permissions $db $msg_id $user_id] } {
	    ad_return_error "Permission Denied" "You do not have permission to retrieve this message part."
	    return
	}

	ReturnHeaders [database_to_tcl_string $db "select content_type
from wm_attachments
where msg_id = $msg_id
  and filename = '[DoubleApos $filename]'"]

	ns_ora write_blob $db "select data
from wm_attachments
where msg_id = $msg_id
  and filename = '[DoubleApos $filename]'"
    }
}
