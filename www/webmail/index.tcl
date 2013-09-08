# /webmail/index.tcl

ad_page_contract {
    Displays a list of messages in a mailbox. Gives UI for selecting, deleting,
    reordering, and filtering.
    
    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id index.tcl,v 1.15.2.10 2000/09/22 01:39:27 kevin Exp
} {
    { orderby "date_value" }
    mailbox_id:integer,optional
}


set user_id [ad_maybe_redirect_for_registration]

set filters [ad_get_client_property -browser t "webmail" "filters"]

# If mailbox_id was specified, then store it as a session property if it is
# different from what we already have.

set cached_mailbox_id [ad_get_client_property -browser t "webmail" "mailbox_id"]
if { ![exists_and_not_null mailbox_id] } {
    set mailbox_id $cached_mailbox_id
} else {
    if { $cached_mailbox_id != $mailbox_id } {
	ad_set_client_property -browser t "webmail" "mailbox_id" $mailbox_id
    }
}

proc select_default_mailbox { user_id } {
    upvar mailbox_id mailbox_id
    upvar mailbox_name mailbox_name

    set mailbox_id [db_string mboxid "select mailbox_id
from wm_mailboxes
where creation_user = :user_id
and name = 'INBOX'" -default ""]
    if { $mailbox_id == "" } {
	ad_return_warning "No Account" "You have not been set up with an email account
on this system. Please contact the system administrator to hook you up and try again."
	return -code return
    }
    ad_set_client_property -browser t "webmail" "mailbox_id" $mailbox_id
    set mailbox_name "INBOX"
}

if { [empty_string_p $mailbox_id] } {
    select_default_mailbox $user_id
} else {
    # Check to see if this user actually owns this mailbox.
    
    if { ![db_0or1row mailboxname "select name as mailbox_name
from wm_mailboxes
where mailbox_id = :mailbox_id
  and creation_user = :user_id"] } {
	# ad_return_error "Permission Denied" "You do not have permission to access this mailbox."
	
	ns_log Notice "WEBMAIL WARNING: user $user_id attempted to access mailbox $mailbox_id"
	select_default_mailbox $user_id
    }
}


# If orderby was specified, change the value that we have cached for it.
set cached_orderby [ad_get_client_property -browser t "webmail" "orderby"]
if { ![exists_and_not_null orderby] } {
    set orderby $cached_orderby
    if { [empty_string_p $orderby] } {
	set orderby "date_value"
    }
} else {
    if { $cached_orderby != $orderby } {
	ad_set_client_property -browser t "webmail" "orderby" $orderby
    }
}

# Format an element differently for read or deleted messages.
proc wm_format_for_seen_or_deleted { seen_p deleted_p str } {
    if [empty_string_p $str] {
	set result "<i>(empty)</i>"
    } else {
	set result $str
    }
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

proc_doc wm_filter_clause { bind filters } {
    Return a where clause restricting a query based on the given filter specifications.
    bind is an ns_set of the bind variables. We modify this ns_set based on the specified filters
} {
    set ctx_key 1

    set clauses [list]
    foreach filter $filters {
	# Prefix the filter_name with "filter_" to make it easier to prevent name collisions in the ns_set
	# of bind variables
	set switch_filter_name "[lindex $filter 0]"
	set filter_name "filter_$switch_filter_name"
	regsub -all {\-} $filter_name "_" filter_name
	set filter_value [lindex $filter 1]

	switch -- $switch_filter_name {
	    "last-n-days" {
		lappend clauses "date_table.time_value > sysdate - :$filter_name"
	    }
	    "sent-after" {
		lappend clauses "date_table.time_value > to_date(:$filter_name, 'YYYY-MM-DD HH24:MI:SS')"
	    }
	    "sent-before" {
		lappend clauses "date_table.time_value < to_date(:$filter_name, 'YYYY-MM-DD HH24:MI:SS')"
	    }
	    "sent-on" {
		lappend clauses "trunc(date_table.time_value) = :$filter_name"
	    }
	    "author" {
		set filter_value "%$filter_value%"
		lappend clauses "from_table.value like :$filter_name"
	    }
	    "subject" {
		set filter_value "%$filter_value%"
		lappend clauses "subject_table.value like :$filter_name"
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
		set filter_value "%$filter_value%"
		lappend clauses "exists (select 1 from wm_recipients where (email like :$filter_name or name like :$filter_name) and wm_recipients.msg_id = m.msg_id)"
	    }
	    "any-header" {
		set filter_value "%$filter_value%"
		lappend clauses "exists (select 1 from wm_headers where value like :$filter_name and wm_headers.msg_id = mmm.msg_id)"
	    }
	    "body" {
		set filter_value [string trim $filter_value]
		ns_set put $bind filter_query_string [db_string bodyrewrite "select im_convert(:filter_value) from dual"]
		lappend clauses "a.msg_id(+) = m.msg_id and (contains(m.body, :filter_query_string, $ctx_key) > 0 or contains(a.data, :filter_query_string, [expr $ctx_key + 1]) > 0)"
		incr ctx_key 2
	    }
	}
	ns_set put $bind $filter_name $filter_value
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

	append results "<li>[philg_quote_double_quotes "$filter_name: $filter_value"] <font size=-1><a href=\"filter-delete?[export_url_vars filter]\">clear</a></font>\n"
    }
    if { ![empty_string_p $results] } {
	set results "<ul>
$results<br>
<font size=-1><a href=\"filter-delete-all\">clear all</a></font>
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

# Create an ns_set of the variables to bind... Need this for ad_table
set bind_vars [ns_set create]
ns_set put $bind_vars mailbox_id $mailbox_id


# Use ad_table to generate a sortable html table for the list of messages.

set table_def {
    { "" "&nbsp;" \
	  {m.msg_id $order} \
	  {<td><font size=-1>[accumulate_msg_id $msg_id $seen_p $deleted_p]<input type=checkbox name=msg_ids value=$msg_id></font></td>} } 
    { from_value "Sender" \
	  { from_value $order } \
	  { <td><font size=-1><a href=message?[export_url_vars msg_id]>[wm_format_for_seen_or_deleted $seen_p $deleted_p [philg_quote_double_quotes $from_value]]</a></font></td> } }
    { subject_value "Subject" \
	  { subject_value $order } \
	  { <td><font size=-1>[wm_format_for_seen_or_deleted $seen_p $deleted_p [ad_decode $subject_value "" "&nbsp;" $subject_value]]</font></td> } } 
    { seen_p "U" \
	  { seen_p $order } \
	  {<td align=center><font size=-1>[ad_decode $seen_p "f" "<img src=\"/graphics/checkmark.gif\">" "&nbsp;"]</font></td> } }
    { deleted_p "D" \
	  { deleted_p $order } \
	  { <td align=center><font size=-1>[ad_decode $deleted_p "t" "<img src=\"/graphics/checkmark.gif\">" "&nbsp;"]</font></td> } }
    { date_value "Date" \
	  { date_value $order } \
	  { <td align=center><font size=-1>[wm_format_for_seen_or_deleted $seen_p $deleted_p $pretty_date_value]</font></td> } }
}
				

set sql "select m.msg_id, from_table.value as from_value, subject_table.value as subject_value, 
                date_table.time_value as date_value, to_char(date_table.time_value, 'YYYY-MM-DD HH24:MI') as pretty_date_value, 
                mmm.seen_p, mmm.deleted_p
           from wm_messages m, wm_headers from_table, wm_headers subject_table, wm_headers date_table, 
                wm_message_mailbox_map mmm[wm_query_extra_tables $filters]
          where mmm.mailbox_id = :mailbox_id
            and m.msg_id = mmm.msg_id
            and m.msg_id = from_table.msg_id(+)
            and from_table.lower_name(+) = 'from'
            and m.msg_id = subject_table.msg_id(+)
            and subject_table.lower_name(+) = 'subject'
            and m.msg_id = date_table.msg_id(+)
            and date_table.lower_name(+) = 'date' [wm_filter_clause $bind_vars $filters] [ad_order_by_from_sort_spec $orderby $table_def]"
            

with_catch errmsg {
    set message_headers [ad_table -Torderby $orderby -Ttable_extra_html "border=0 cellspacing=1 cellpadding=0 width=100%" -Tband_colors [list "\#ffffff" "\#f0f0f0"] -Trows_per_page 50 -Tasc_order_img "<img src=/graphics/up.gif alt=\"^\">" -Tdesc_order_img "<img src=/graphics/down.gif alt=\"v\">" -bind $bind_vars webmail_message_headers $sql $table_def]
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
set folder_select_options [db_html_select_value_options -select_option $mailbox_id mailbox_selection "select mailbox_id, name
from wm_mailboxes
where creation_user = :user_id"]

# How many messages we have, and how many of those are unread.
set n_messages [db_string mboxcount "select count(*)
from wm_message_mailbox_map
where mailbox_id = :mailbox_id"]

set n_unread_messages [db_string unreadcount "select count(*)
from wm_message_mailbox_map
where mailbox_id = :mailbox_id
  and seen_p = 'f'"]

db_release_unused_handles

set possible_days [list 1 2 7 30 0]
foreach day $possible_days {
    set day_display [ad_decode $day 0 "all" $day]
    lappend days_url_list "<a href=\"summary?last_n_days=$day\">$day_display</a>"
}
set day_selection_list "<font size=-1>\[ [join $days_url_list " | "] \]</font>"


# If we have specified a refresh, let's put it in the call to ad_header
set refresh_seconds [ad_get_client_property -browser t "webmail" "seconds_between_refresh"]
if { ! [empty_string_p $refresh_seconds] && $refresh_seconds > 0 } {
    set extra_stuff "<meta http-equiv=\"Refresh\" content=\"$refresh_seconds; url=[ns_conn url]?[export_ns_set_vars url]\">"
} else {    
    set extra_stuff ""
}
 
doc_return  200 text/html "[ad_header "WebMail" $extra_stuff]

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
<table border=0 width=100%>
<tr>
  <td align=right>$day_selection_list &nbsp; \[<a href=preferences>preferences</a>\]</td>
</tr>
</table>

 [ad_decode $n_messages 1 "1 message" "$n_messages messages"],
 [ad_decode $n_unread_messages 1 "1 unread" "$n_unread_messages unread"]

<table border=0 width=100%>

<tr valign=top>
<td><form action=\"folder-move-to\">
<font size=-1>
<select name=mailbox_id>
$folder_select_options
<option value=\"@NEW\">New Folder</option>
</select>
<input type=submit value=\"Go\">
</font>
</form>
</td>

<td align=right><a href=\"expunge?[export_url_vars mailbox_id]\">Expunge Deleted Messages</a><br>
<a href=\"message-send\">Send Mail</a>
</td>
</tr>
</table>

<table border=0 width=100%>
<tr valign=top><td><form action=\"filter-add\" method=POST>
Filters: 
<font size=-1>
<select name=filter_type>
<option value=\"author\">Author</option>
<option value=\"recipient\">Recipient</option>
<option value=\"subject\">Subject</option>
<option value=\"last-n-days\">Last N Days</option>
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
<form name=messageList action=\"process-selected-messages\" method=POST>
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

<a href=\"expunge?[export_url_vars mailbox_id]\">Expunge Deleted Messages</a><p>
<a href=\"message-send\">Send Mail</a>
" ""]

[ad_footer]
"
