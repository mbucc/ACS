# /webmail/summary.tcl

ad_page_contract {
    Display a summary of activity for the current mailbox.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-28
    @cvs-id summary.tcl,v 1.6.2.7 2000/10/23 02:42:13 jsc Exp
} {
    {last_n_days:integer 0}
}

set user_id [ad_maybe_redirect_for_registration]

set mailbox_id [ad_get_client_property -browser t "webmail" "mailbox_id"]

if { [empty_string_p $mailbox_id] } {
    # Select the default mailbox.
    set mailbox_id [db_string mailbox_id "select mailbox_id
from wm_mailboxes
where creation_user = :user_id
and name = 'INBOX'" -default ""]
    if { $mailbox_id == "" } {
	ad_return_warning "No Account" "You have not been set up with an email account
on this system. Please contact the system administrator to hook you up and try again."
	return
    }
    ad_set_client_property -browser t "webmail" "mailbox_id" $mailbox_id
    set mailbox_name "INBOX"
} else {
    # Check to see if this user actually owns this mailbox.
    set mailbox_exists_p [db_0or1row mailbox_name "select name as mailbox_name
from wm_mailboxes
where mailbox_id = :mailbox_id
  and creation_user = :user_id"]
    if { !$mailbox_exists_p } {
	ad_return_error "Permission Denied" "You do not have permission to access this mailbox."
	ns_log Notice "WEBMAIL WARNING: user $user_id attempted to access mailbox $mailbox_id"
	return
    }
}


# Options for folder selection.
set folder_select_options [db_html_select_value_options -select_option $mailbox_id mailbox_selection "select mailbox_id, name
from wm_mailboxes
where creation_user = :user_id"]

# Last days selection.

set days_url_list [list]

set possible_days [list 1 2 7 30 0]
foreach day $possible_days {
    set day_display [ad_decode $day 0 "all" $day]

    if { $day == $last_n_days } {
	lappend days_url_list $day_display
    } else {
	lappend days_url_list "<a href=\"summary?last_n_days=$day\">$day_display</a>"
    }
}
set day_selection_list "<font size=-1>\[ [join $days_url_list " | "] \]</font>"


# Number of messages unread/deleted/total
if { $last_n_days == 0 } {
    set count_query "select sum(decode(seen_p, 'f', 1, 0)) as n_unread, sum(decode(deleted_p, 't', 1, 0)) as n_deleted, sum(1) as n_total
from wm_message_mailbox_map
where mailbox_id = $mailbox_id"
} else {
    set count_query "select sum(decode(seen_p, 'f', 1, 0)) as n_unread, sum(decode(deleted_p, 't', 1, 0)) as n_deleted, sum(1) as n_total
from wm_message_mailbox_map mmm, wm_headers h
where  mailbox_id = $mailbox_id
and mmm.msg_id = h.msg_id
and h.lower_name = 'date'
and h.time_value > sysdate - $last_n_days"
}

db_1row count_query $count_query

# Author summary
if { $last_n_days == 0 } {
    set author_summary_query {
	select value as author, count(*) as n_messages
	from wm_headers h, wm_message_mailbox_map mmm
	where lower_name = 'from'
	and h.msg_id = mmm.msg_id
	and mmm.mailbox_id = :mailbox_id
	and mmm.deleted_p = 'f'
	group by value
	order by 2 desc, value
    }
} else {
    set author_summary_query {
	select /*+ FIRST_ROWS */ h1.value as author, count(*) as n_messages
	from wm_headers h1, wm_headers h2, wm_message_mailbox_map mmm
	where h1.lower_name = 'from'
	and h2.lower_name = 'date'
	and h1.msg_id = h2.msg_id
	and h2.time_value > sysdate - :last_n_days
	and h1.msg_id = mmm.msg_id
	and mmm.mailbox_id = :mailbox_id
	and mmm.deleted_p = 'f'
	group by h1.value
	order by 2 desc, h1.value
    }
}

set author_summary ""

db_foreach author_summary $author_summary_query {
    append author_summary "<input type=checkbox name=\"author\" value=\"[philg_quote_double_quotes $author]\"> $n_messages: <a href=\"filter-add?filter_type=author&filter_term=[ns_urlencode $author]\">[philg_quote_double_quotes $author]</a></font><br>\n"
}

# Recipient Summary
if { $last_n_days == 0 } {
    set recipient_summary_query {
	select email, count(*) as n_messages
	from wm_recipients r, wm_message_mailbox_map mmm
	where r.msg_id = mmm.msg_id
	and mmm.mailbox_id = :mailbox_id
	and mmm.deleted_p = 'f'
	group by email
	order by 2 desc, email
    }
} else {
    set recipient_summary_query {
	select email, count(*) as n_messages
	from wm_recipients r, wm_headers h, wm_message_mailbox_map mmm
	where h.lower_name = 'date'
	and r.msg_id = h.msg_id
	and h.time_value > sysdate - :last_n_days
	and r.msg_id = mmm.msg_id
	and mmm.mailbox_id = :mailbox_id
	and mmm.deleted_p = 'f'
	group by email
	order by 2 desc, email
    }
}

set recipient_summary ""

db_foreach recipient_summary $recipient_summary_query {
    append recipient_summary "<li>$n_messages: <a href=\"filter-add?filter_type=recipient&filter_term=[ns_urlencode $email]\">[philg_quote_double_quotes $email]</a>\n"
}

db_release_unused_handles

if { $last_n_days == 0 } {
    set title "$mailbox_name Summary: All Messages"
} elseif { $last_n_days == 1 } {
    set title "$mailbox_name Summary: Last 24 Hours"
} else {
    set title "$mailbox_name Summary: Last $last_n_days Days"
}


doc_return  200 text/html "[ad_header $title]

<h2>$title</h2>

 [ad_context_bar_ws [list "index" "WebMail"] "Summary"]

<hr>
<table width=100%>
<tr><td align=right>$day_selection_list</td></tr>
</table>

<form action=\"folder-move-to\">
[export_form_vars last_n_days]
<input type=hidden name=return_url value=\"summary\">
[export_form_vars last_n_days]
<font size=-1>
<select name=mailbox_id>
$folder_select_options
</select>
<input type=submit value=\"Go\">
</font>
</form>

<blockquote>
<table border=0>
<tr><td>Unread: <td align=right>$n_unread</tr>
<tr><td>Deleted: <td align=right>$n_deleted</tr>
<tr><td>Total: <td align=right>$n_total</tr>
</table>
</blockquote>

<h3>Authors</h3>
<blockquote>
<form action=author-delete method=POST>
[export_form_vars last_n_days]
<input type=submit value=\"Delete Marked Messages\">
<p>
$author_summary
</form>
</blockquote>

<h3>Recipients</h3>

<ul>
$recipient_summary
</ul>


[ad_footer]
"
