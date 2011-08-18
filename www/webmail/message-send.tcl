# /webmail/message-refile.tcl
# by jsc@arsdigita.com (2000-02-23)

# Present form to send message, populating certain fields if this is a response.

ad_page_variables {{response_to_msg_id ""} {respond_to_all 0}}

# If response_to_msg_id is supplied, this is a response to the given msg_id.
# If respond_to_all is set to a true value, all recipients will be Cc'ed.

set msg_body ""
set subject ""
set page_title "Send Mail"

set user_id [ad_verify_and_get_user_id]
set db [ns_db gethandle]

set cc ""

if { ![empty_string_p $response_to_msg_id] } {

    validate_integer response_to_msg_id $response_to_msg_id

    if { ![wm_check_permissions $db $response_to_msg_id $user_id] } {
	ad_return_error "Permission Denied" "You do not have permission to access this message to respond to it."
	return
    }

    set msg_body [database_to_tcl_string $db "select body
from wm_messages
where msg_id = $response_to_msg_id"]

    set subject [database_to_tcl_string_or_null $db "select value
from wm_headers
where msg_id = $response_to_msg_id
  and lower_name = 'subject'"]

    if { ![empty_string_p $subject] } {
	set page_title "Response to \"$subject\""

	if { ![regexp -nocase {^re:} $subject] } {
	    set subject "Re: $subject"
	}
    } else {
	set page_title "Response"
    }

    set to [database_to_tcl_string_or_null $db "select wm_response_address($response_to_msg_id) from dual"]

    if $respond_to_all {
	set cc [join [database_to_tcl_list $db "select email from wm_recipients where msg_id = $response_to_msg_id"] ", "]
    }
    set context_bar [ad_context_bar_ws \
			 [list "index.tcl" "WebMail"] \
			 [list "message.tcl?msg_id=$response_to_msg_id" "One Message"] \
			 "Response"]
} else {
    set context_bar [ad_context_bar_ws [list "index.tcl" "WebMail"] "Send Mail"]
    set to ""
}


set from_options [database_to_tcl_list $db "select email_user_name || '@' || full_domain_name as from_address
from wm_email_user_map eum, wm_domains d
where user_id = $user_id
  and eum.domain = d.short_name
order by 1"]

if { [llength $from_options] > 1 } {
    set from_field "<select name=from>\n"
    foreach option $from_options {
	append from_field "<option>$option</option>\n"
    }
    append from_field "</select>"
} else {
    set from [lindex $from_options 0]
    set from_field "$from\n[export_form_vars from]\n"
}

set outgoing_msg_id [database_to_tcl_string $db "select wm_outgoing_msg_id_sequence.nextval from dual"]

ns_db releasehandle $db

ns_return 200 text/html "[ad_header $page_title]
<h2>$page_title</h2>

$context_bar

<hr>

<form action=\"message-send-2.tcl\" action=POST>
 [export_form_vars response_to_msg_id outgoing_msg_id]

<blockquote>

<table border=0 width=90%>
<tr><td align=right>To: </td>
<td><input type=text name=to size=40 value=\"[philg_quote_double_quotes $to]\"></td>
</tr>

<tr><td align=right>From: </td>
<td>$from_field</td>
</tr>

<tr><td align=right>Cc: </td>
<td><input type=text name=cc size=40 value=\"[philg_quote_double_quotes $cc]\"></td>
</tr>

<tr><td align=right>Subject: </td>
<td><input type=text name=subject size=80 value=\"[philg_quote_double_quotes $subject]\"></td>
</tr>

</table>

<textarea wrap=virtual name=body rows=20 cols=80>[wm_quote_message $to $msg_body]</textarea>

</blockquote>

<center>
<input type=submit value=\"Preview Message\">
</center>

</form>

[ad_footer]
"



