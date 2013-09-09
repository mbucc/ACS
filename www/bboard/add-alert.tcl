# /www/bboard/add-alert.tcl
ad_page_contract {
    Adds a new bboard alert.

    @param topic_id the topic id of the topic
    @param topic the name of the topic to add a user alert for

    @cvs-id add-alert.tcl,v 3.2.2.5 2000/09/22 01:36:41 kevin Exp
} {
    topic_id:integer,notnull
    topic:notnull
}

# -----------------------------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

if { [bboard_get_topic_info] == -1 } {
    return
}

set keyword_limit_option ""
if { [bboard_pls_blade_installed_p] == 1 } {
    set keyword_limit_option "2: Decide if you want to limit your notification by keyword <p>

Keywords:  <input name=keywords type=text size=40> (separate by spaces)

<p>

\[Note: if you type anything here, you will <em>only</em> get notified
when a posting matches <em>at least one</em> of the keywords.
Keywords are matched against the subject line, message body, author
name, and author email address. \]

<P>

"
}

append page_content "[bboard_header "Add Alert"]

<h2>Add an Alert</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] [list [bboard_raw_backlink $topic_id $topic $presentation_type 0] $topic] "Add Alert"]

<hr>

"

# our topic variable is about to get bashed
set current_topic $topic
set current_topic_id $topic_id

# let's first see if this person has any existing alerts
set counter 0

db_foreach get_existing_user_alerts "
select 
  bea.*, 
  bea.rowid, 
  bboard_topics.topic
from bboard_email_alerts bea, bboard_topics
where bea.user_id = :user_id
  and bboard_topics.topic_id = bea.topic_id
order by frequency" {

    incr counter
    if { $valid_p == "f" } {
	# alert has been disabled for some reason
	set status "Disabled"
	set action "<a href=\"alert-reenable?rowid=[ns_urlencode $rowid]\">Re-enable</a>"
    } else {
	# alert is enabled
	set status "Enabled"
	set action "<a href=\"alert-disable?rowid=[ns_urlencode $rowid]\">Disable</a>"
    }
    if { [bboard_pls_blade_installed_p] == 1 } {
	append existing_alert_rows "<tr><td>$status<td>$action<td>$topic<td>$frequency<td>\"$keywords\"</tr>\n"
    } else {
	append existing_alert_rows "<tr><td>$status<td>$action<td>$topic<td>$frequency</tr>\n"
    }

}

if  { $counter > 0 } {
    set keyword_header ""
    if { [bboard_pls_blade_installed_p] == 1 } {
	set keyword_header "<th>Keywords</th>"
    }
    append page_content "<h3>Your existing alerts</h3>

<blockquote>
<table>
<tr><th>Status<th>Action</th><th>Topic</th><th>Frequency</th>$keyword_header</tr>

$existing_alert_rows
</table>
</blockquote>
"
}

append page_content "

<h3>Add a new alert</h3>

If you'd like to keep up with this forum but don't want to check the
Web page all the time, then this forum will come to you!  By filling
out this form, you can ask for email notification of new postings that
fit your interests.

<p>

<form method=POST action=\"add-alert-2\">
<input name=topic type=hidden value=\"$current_topic\">
<input name=topic_id type=hidden value=\"$current_topic_id\">

1: How often would you like to be notified via email?

<P>

<input name=frequency value=\"instant\" type=radio> Instantly (as soon as a posting is made)

<br>
or...
<br>

<input name=frequency value=\"daily\" type=radio> Daily 
<input name=frequency value=\"Monday/Thursday\" type=radio checked> Monday and Thursday
<input name=frequency value=\"weekly\" type=radio> Weekly

<p>

$keyword_limit_option

<center>

<input type=submit value=\"Add My Alert\">

</center>

</form>

</form>

[bboard_footer]
"



doc_return  200 text/html $page_content