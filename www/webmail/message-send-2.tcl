# /webmail/message-send-2.tcl

ad_page_contract {
    Present message for review and give form to attach files.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id message-send-2.tcl,v 1.5.2.11 2001/01/12 00:24:39 khy Exp
} {
    outgoing_msg_id:integer,notnull,verify
    { response_to_msg_id:integer "" } 
    { to:allhtml "" }
    { cc:allhtml "" }
    { subject "" }
    { from "" }
    { body:allhtml "" }
}

set user_id [ad_verify_and_get_user_id]

set header_sort_key 0

db_transaction {
    # Insert body or retrieve saved body.
    if { [empty_string_p $to] && [empty_string_p $cc] && [empty_string_p $subject] && [empty_string_p $from] && [empty_string_p $body] } {
	# We are attaching messages to an already inserted message.
	# Retrieve the saved message as cleaned_body.

	set msg_exists_p [db_0or1row msg_info "select body as cleaned_body, creation_user
from wm_outgoing_messages
where outgoing_msg_id = :outgoing_msg_id"]

	if { ! $msg_exists_p } {
	    ad_return_error "No Such Message" "The specified message being composed no longer exists. You took too long to send it and it got cleaned up."
	    return
	}
	
	if { $creation_user != $user_id } {
	    ad_return_error "Permission Denied" "You do not have permission to access the specified message."
	    return
	}
    } else {
	# We got a body; we are inserting for the first time, or the user went back and
	# resubmitted the form.
	set creation_user [db_string msg_creator "select creation_user
from wm_outgoing_messages
where outgoing_msg_id = :outgoing_msg_id" -default ""]

	db_with_handle db {
	    if { $creation_user == "" } {
		# No previous message.
		set cleaned_body [wrap_string $body]
		
		ns_ora clob_dml $db "insert into wm_outgoing_messages (outgoing_msg_id, body, creation_user)
 values ($outgoing_msg_id, empty_clob(), $user_id)
returning body into :1" $cleaned_body
	    } elseif { $creation_user == $user_id } {
		# Reinserted message.
		set cleaned_body [wrap_string $body]
		
		ns_ora clob_dml $db "update wm_outgoing_messages set body = empty_clob() where outgoing_msg_id = :outgoing_msg_id returning body into :1" $cleaned_body
	    } else {
		ad_return_error "Permission Denied" "You do not have permission to update the message you are trying to compose."
		return
	    }
	}
    }

    # Process headers if not already done.
    if { [db_string header_count "select count(*)
from wm_outgoing_headers
 where outgoing_msg_id = :outgoing_msg_id"] == 0 } {

	if { [empty_string_p $to] && [empty_string_p $cc] } {
	    ad_return_error "No Recipients" "You did not specify any recipients for your message."
	    return
	}

	# Validate the from field.
	# Can't name the bind variable as "from" because it is a reserved word
	set from_user $from
	if { [db_string validate_from_field "select count(*)
from wm_email_user_map eum, wm_domains d
where user_id = :user_id
  and eum.domain = d.short_name
  and email_user_name || '@' || full_domain_name = :from_user"] == 0 } {
	    ad_return_error "Permission Denied" "You cannot send email as \"$from\"."
	    return
	}

	# Insert standard headers.
	foreach field_spec [list [list To $to] [list Cc $cc] [list Subject $subject] [list From $from]] {
	    set name [lindex $field_spec 0]
	    set value [lindex $field_spec 1]
	    if { ![empty_string_p $value] } {
		db_dml header_insert "insert into wm_outgoing_headers (outgoing_msg_id, name, value, sort_order)
 values ($outgoing_msg_id, '[DoubleApos $name]', '[DoubleApos $value]', $header_sort_key)"
		incr header_sort_key
	    }
	}
	
	# Figure out References field.
	if { ![empty_string_p $response_to_msg_id] } {
	    
	    if { ![wm_check_permissions $response_to_msg_id $user_id] } {
		ad_return_error "Permission Denied" "You do not have permission to access this message to respond to it."
		return
	    }
	    
	    set old_references [db_string header_value "select value
from wm_headers
where msg_id = :response_to_msg_id
  and lower_name = 'references'" -default ""]
	    
	    set old_message_id [db_string message_id "select message_id
from wm_messages
where msg_id = :response_to_msg_id"]
	    
	    set references [string trim "$old_references $old_message_id"]
	    if { ![empty_string_p $references] } {
		db_dml references_insert "insert into wm_outgoing_headers (outgoing_msg_id, name, value, sort_order)
 values (:outgoing_msg_id, 'References', :references, :header_sort_key)"
		incr header_sort_key
	    }
	}
    }

    if { ![empty_string_p $response_to_msg_id] } {
	set context_bar [ad_context_bar_ws \
			     [list "index" "WebMail"] \
			     [list "message?msg_id=$response_to_msg_id" "One Message"] \
			     "Response"]
	set title "Response"
    } else {
	set context_bar [ad_context_bar_ws [list "index" "WebMail"] "Compose Mail"]
	set title "Compose Mail"
    }
} on_error {
    ad_return_error "Error Composing Message" "An error occured while composing your message:
<pre>
$errmsg
</pre>"
    return
}



# Format message body.
set msg ""

db_foreach header_rows {
    select name || ': ' || value as field
    from wm_outgoing_headers
    where outgoing_msg_id = :outgoing_msg_id
    order by sort_order
} {
    append msg "[philg_quote_double_quotes $field]\n"
}
append msg "\n$cleaned_body"


# Format attachments.

set attachments "<ul>\n"

db_foreach attachments {
    select filename, content_type
    from wm_outgoing_message_parts
    where outgoing_msg_id = :outgoing_msg_id
    order by sort_order
} {
    append attachments "<li>$filename ($content_type)\n"
}
append attachments "</ul>"



doc_return  200 text/html "[ad_header $title]
<h2>$title</h2>

$context_bar

<hr>

<form enctype=multipart/form-data action=\"message-send-add-attachment\" method=POST>
 [export_form_vars -sign outgoing_msg_id]
[export_form_vars response_to_msg_id]
Attachments:
$attachments
<p>

<font size=-1><input type=file name=upload_file><br><input type=submit value=\"Attach File\"></font> 
</form>

<p>
<p>

<center>
<form action=\"message-send-3\" action=POST>
[export_form_vars outgoing_msg_id response_to_msg_id]
<input type=submit value=\"Send Message\">
</form>
</center>


<blockquote>
<pre>
$msg
</pre>
</blockquote>



[ad_footer]
"

