# /webmail/index.tcl
# by jsc@arsdigita.com (2000-02-23)

# Displays a list of messages in a mailbox. Gives UI for selecting, deleting,
# reordering, and filtering.


set_form_variables 0
# sort_by, mailbox_id (optional)

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode "/webmail/"]"
    return
}

set db [ns_db gethandle]

set filters [ad_get_client_property "webmail" "filters"]

# If mailbox_id was specified, then store it as a session property if it is
# different from what we already have.

set cached_mailbox_id [ad_get_client_property "webmail" "mailbox_id"]
if { ![exists_and_not_null mailbox_id] } {
    set mailbox_id $cached_mailbox_id
} else {
    if { $cached_mailbox_id != $mailbox_id } {
	ad_set_client_property -persistent f "webmail" "mailbox_id" $mailbox_id
    }
}

if { [empty_string_p $mailbox_id] } {
    # Select the default mailbox.
    set mailbox_id [database_to_tcl_string_or_null $db "select mailbox_id
from wm_mailboxes
where creation_user = $user_id
and name = 'INBOX'"]
    if { $mailbox_id == "" } {
	ad_return_warning "No Account" "You have not been set up with an email account
on this system. Please contact the system administrator to hook you up and try again."
	return
    }
    ad_set_client_property -persistent f "webmail" "mailbox_id" $mailbox_id
    set mailbox_name "INBOX"
} else {
    # Check to see if this user actually owns this mailbox.
    set selection [ns_db 0or1row $db "select name as mailbox_name
from wm_mailboxes
where mailbox_id = $mailbox_id
  and creation_user = $user_id"]
    if { $selection == "" } {
	ad_return_error "Permission Denied" "You do not have permission to access this mailbox."
	ns_log Notice "WEBMAIL WARNING: user $user_id attempted to access mailbox $mailbox_id"
	return
    } else {
	set_variables_after_query
    }
}


# If sort_by was specified, change the value that we have cached for it.
set cached_sort_by [ad_get_client_property "webmail" "sort_by"]
if { ![exists_and_not_null sort_by] } {
    set sort_by $cached_sort_by
    if { [empty_string_p $sort_by] } {
	set sort_by "date_value"
    }
} else {
    if { $cached_sort_by != $sort_by } {
	ad_set_client_property -persistent f "webmail" "sort_by" $sort_by
    }
}


# Format an element differently for read or deleted messages.
proc wm_format_for_seen_or_deleted { seen_p deleted_p str } {
    set result $str
    if { $seen_p == "f" } {
	set result "<b>$result</b>"
    }
    if { $deleted_p == "t" } {
	set result "<font color=\"\#505050\">$result</font>"
    }
    return $result
}



# Return a list of extra tables to add to the query for certain filters.
proc wm_query_extra_tables { filters } {
    # Keep track of already added tables, so we don't add it more than
    # once.
    set filter_seen() ""
    set extra_tables ""

    foreach filter $filters {
	set filter_name [lindex $filter 0]

	if [info exists filter_seen($filter_name)] {
	    continue
	}

	switch -- $filter_name {
	    "body" {
		append extra_tables ", wm_attachments a"
	    }
	}
	set filter_seen($filter_name) 1
    }
    return $extra_tables
}

# Return a where clause restricting a query based on the given filter specifications.
proc wm_filter_clause { db filters } {
    set ctx_key 1

    set clauses [list]
    foreach filter $filters {
	set filter_name [lindex $filter 0]
	set filter_value [DoubleApos [lindex $filter 1]]

	switch -- $filter_name {
	    "sent-after" {
		lappend clauses "date_table.time_value > to_date('$filter_value', 'YYYY-MM-DD HH24:MI:SS')"
	    }
	    "sent-before" {
		lappend clauses "date_table.time_value < to_date('$filter_value', 'YYYY-MM-DD HH24:MI:SS')"
	    }
	    "sent-on" {
		lappend clauses "trunc(date_table.time_value) = '$filter_value'"
	    }
	    "author" {
		lappend clauses "from_table.value like '%$filter_value%'"
	    }
	    "subject" {
		lappend clauses "subject_table.value like '%$filter_value%'"
	    }
	    "read" {
		lappend clauses "seen_p = 't'"
	    }
	    "unread" {
		lappend clauses "seen_p = 'f'"
	    }
	    "deleted" {
		lappend clauses "deleted_p = 't'"
	    }
	    "undeleted" {
		lappend clauses "deleted_p = 'f'"
	    }
	    "recipient" {
		lappend clauses "exists (select 1 from wm_recipients where (email like '%$filter_value%' or name like '%$filter_value%') and wm_recipients.msg_id = m.msg_id)"
	    }
	    "any-header" {
		lappend clauses "exists (select 1 from wm_headers where value like '%$filter_value%' and wm_headers.msg_id = mum.msg_id)"
	    }
	    "body" {
		set query_string [DoubleApos [database_to_tcl_string $db "select im_convert('[string trim $filter_value]') from dual"]]
		lappend clauses "a.msg_id = m.msg_id and (contains(m.body, '$query_string', $ctx_key) > 0 or contains(a.data, '$query_string', [expr $ctx_key + 1]) > 0)"
		incr ctx_key 2
	    }
	}
    }
    if { [llength $clauses] > 0 } {
	return " and [join $clauses " and "]"
    } else {
	return ""
    }
}


# Returns some HTML displaying the filters currently active, and provide links
# to clear them.
proc wm_filter_info { current_filters } {
    set results ""
    foreach filter $current_filters {
	set filter_name [lindex $filter 0]
	set filter_value [lindex $filter 1]

	append results "<li>[philg_quote_double_quotes "$filter_name: $filter_value"] <font size=-1><a href=\"filter-delete.tcl?[export_url_vars filter]\">clear</a></font>\n"
    }
    if { ![empty_string_p $results] } {
	set results "<ul>
$results<br>
<font size=-1><a href=\"filter-delete-all.tcl\">clear all</a></font>
</ul>
"
    }
    return $results
}

# Accumulates message IDs into a page-local global variable.
global current_messages
set current_messages ""
global message_count
set message_count 0

# This procedure gets called for each row of the sortable table.
proc accumulate_msg_id { msg_id seen_p deleted_p } {
    global current_messages
    global message_count

    lappend current_messages [list $msg_id $seen_p $deleted_p]
    incr message_count
    return ""
}


# Use the sortable_table proc defined in 00-ad-utilities.tcl to generate the HTML
# for the list of messages.
with_catch errmsg {
    set message_headers [sortable_table $db \
			 "select m.msg_id, from_table.value as from_value, subject_table.value as subject_value, date_table.time_value as date_value, to_char(date_table.time_value, 'YYYY-MM-DD HH24:MI') as pretty_date_value, mum.seen_p, mum.deleted_p
from wm_messages m, wm_headers from_table, wm_headers subject_table, wm_headers date_table, wm_message_user_map mum[wm_query_extra_tables $filters]
where mum.mailbox_id = $mailbox_id
and m.msg_id = mum.msg_id
and m.msg_id = from_table.msg_id(+)
and from_table.lower_name(+) = 'from'
and m.msg_id = subject_table.msg_id(+)
and subject_table.lower_name(+) = 'subject'
and m.msg_id = date_table.msg_id(+)
and date_table.lower_name(+) = 'date'
 [wm_filter_clause $db $filters]" \
			 [list \
			      [list "" "" {[accumulate_msg_id $msg_id $seen_p $deleted_p]<input type=checkbox name=msg_ids value=$msg_id>}] \
			      [list "from_value" "Sender" "<a href=\"message.tcl?\[export_url_vars msg_id\]\">\[wm_format_for_seen_or_deleted \$seen_p \$deleted_p \"\[philg_quote_double_quotes \$from_value\]\"\]</a>"] \
			      [list "subject_value" "Subject" {[wm_format_for_seen_or_deleted $seen_p $deleted_p [ad_decode $subject_value "" "&nbsp;" $subject_value]]}] \
			      [list "seen_p" "U" {[ad_decode $seen_p "f" "<img src=\"/graphics/checkmark.gif\">" "&nbsp;"]}] \
			      [list "deleted_p" "D" {[ad_decode $deleted_p "t" "<img src=\"/graphics/checkmark.gif\">" "&nbsp;"]}] \
			      [list "date_value" "Date" {[wm_format_for_seen_or_deleted $seen_p $deleted_p $pretty_date_value]}]] \
			 [ns_conn form] \
			 sort_by \
			 $sort_by \
			 50 \
			 "width=100% cellspacing=0 cellpadding=0" \
			 [list "\#f0f0f0" "\#ffffff"] \
			 "" \
			 "" \
			 "size=-1"]
} {
    ad_return_error "WebMail Error" "An error occured while trying to fetch your messages.
Most likely, you entered an invalid filter specification. You can use the links below
to modify your filter settings:
 [wm_filter_info $filters]
<p>
The error message received was:
<pre>
$errmsg
</pre>
"
    return
}

# Save off our accumulated message IDs so that message.tcl can use
# them for next/prev navigation.

ad_set_client_property -persistent f "webmail" "current_messages" $current_messages


# Options for folder selection.
set folder_select_options [db_html_select_value_options $db "select mailbox_id, name
from wm_mailboxes
where creation_user = $user_id" $mailbox_id]


# How many messages we have, and how many of those are unread.
set n_messages [database_to_tcl_string $db "select count(*)
from wm_message_user_map
where mailbox_id = $mailbox_id"]

set n_unread_messages [database_to_tcl_string $db "select count(*)
from wm_message_user_map mum
where mailbox_id = $mailbox_id
  and seen_p = 'f'"]

ns_db releasehandle $db



ns_return 200 text/html "[ad_header "WebMail"]

<script language=JavaScript>
<!--
 function SetChecked(val) {
dml=document.messageList;
len = dml.elements.length;
var i=0;
 for( i=0 ; i<len ; i++) {
 if (dml.elements\[i\].name=='msg_ids') {
dml.elements\[i\].checked=val;
}
}
}

// Necessary for the refile selected buttons. There are two selection widgets
// with the same name in this form. If they are not synched up before the form
// is submitted, only the value of the first one will be used.
 function SynchMoves(primary) {
dml=document.messageList;
if(primary==2) dml.mailbox_id.selectedIndex=dml.mailbox_id2.selectedIndex;
else dml.mailbox_id2.selectedIndex=dml.mailbox_id.selectedIndex;
}
// -->
</script>

<h2>$mailbox_name</h2>

 [ad_context_bar_ws "WebMail"]

<hr>

 [ad_decode $n_messages 1 "1 message" "$n_messages messages"],
 [ad_decode $n_unread_messages 1 "1 unread" "$n_unread_messages unread"]

<table border=0 width=100%>

<tr valign=top>
<td><form action=\"folder-move-to.tcl\">
<font size=-1>
<select name=mailbox_id>
$folder_select_options
<option value=\"@NEW\">New Folder</option>
</select>
<input type=submit value=\"Go\">
</font>
</form>
</td>

<td align=right><a href=\"expunge.tcl?[export_url_vars mailbox_id]\">Expunge Deleted Messages</a><br>
<a href=\"message-send.tcl\">Send Mail</a>
</td>
</tr>
</table>

<table border=0 width=100%>
<tr valign=top><td><form action=\"filter-add.tcl\" method=POST>
Filters: 
<font size=-1>
<select name=filter_type>
<option value=\"author\">Author</option>
<option value=\"recipient\">Recipient</option>
<option value=\"subject\">Subject</option>
<option value=\"sent-after\">Sent After</option>
<option value=\"sent-before\">Sent Before</option>
<option value=\"sent-on\">Sent On</option>
<option value=\"read\">Read</option>
<option value=\"unread\">Unread</option>
<option value=\"deleted\">Deleted</option>
<option value=\"undeleted\">Not Deleted</option>
<option value=\"any-header\">Any Header</option>
<option value=\"body\">Body</option>
</select>

<input type=text name=filter_term size=10>

<input type=submit value=\"Add Filter\">
</font>
</form>

[wm_filter_info $filters]

</td>

<td align=right>
<form name=messageList action=\"process-selected-messages.tcl\" method=POST>
<font size=-1>
Selected Msgs: <input type=submit name=action value=\"Delete\">
<input type=submit name=action value=\"Undelete\">
<input type=submit name=action value=\"Refile\">
<select name=mailbox_id [ad_decode [expr $message_count > 20] 1 "onChange=\"SynchMoves(1)\"" ""]>
$folder_select_options
<option value=\"@NEW\">New Folder</option>
</select>
</font>
</td>
</tr>
</table>


<p>

[ad_decode $message_count 0 "No messages." "
<font size=-1>
<a href=\"javascript:SetChecked(1)\">Check All</a> - 
<a href=\"javascript:SetChecked(0)\">Clear All</a>
</font>

$message_headers

<font size=-1>
<a href=\"javascript:SetChecked(1)\">Check All</a> - 
<a href=\"javascript:SetChecked(0)\">Clear All</a>
"]

<p>

[ad_decode [expr $message_count > 20] 1 "<input type=submit name=action value=\"Delete\">
<input type=submit name=action value=\"Undelete\">
<input type=submit name=action value=\"Refile\">
<select name=mailbox_id2 onChange=\"SynchMoves(2)\">
$folder_select_options
<option value=\"@NEW\">New Folder</option>
</select>
</font>
</form>

<a href=\"expunge.tcl?[export_url_vars mailbox_id]\">Expunge Deleted Messages</a><p>
<a href=\"message-send.tcl\">Send Mail</a>
" ""]

[ad_footer]
"
