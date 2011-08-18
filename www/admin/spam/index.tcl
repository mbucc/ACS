# $Id: index.tcl,v 3.2.2.2 2000/03/15 06:23:46 hqm Exp $
# index.tcl
#
# hqm@arsdigita.com
#
# View/schedule spams
 
set_the_usual_form_variables 0

#maybe 
ReturnHeaders

append pagebody "[ad_admin_header "Spamming"]

<h2>Spamming</h2>

[ad_admin_context_bar "Spamming"]

<hr>
<p>
"

set calendar_details [ns_set create calendar_details]

set db [ns_db gethandle]
 
if {![info exists date] || [empty_string_p $date]} {
    set date [database_to_tcl_string $db "select sysdate from dual"]
}

append pagebody "<center>
<h4>The time is now [database_to_tcl_string $db "select to_char(sysdate,'MM-DD-YYYY HH24:MI:SS') from dual"]</h4>
</center>
"


# get all the spams for this month 
# this query goes a little beyond for simplicity

set selection [ns_db select $db "select sh.spam_id, sh.title, sh.status, dbms_lob.substr(sh.body_plain,100,1) as beginning_of_body, sh.user_class_description, sh.send_date, to_char(send_date,'J') as julian_date, users.user_id, users.first_names || ' ' || users.last_name as user_name, users.email
from spam_history sh, users
where sh.creation_user = users.user_id
and send_date  > to_date('$date','yyyy-mm-dd') - 31 
and send_date  < to_date('$date','yyyy-mm-dd') + 31 
order by send_date desc"]

set count 0 
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr count
    ns_set put $calendar_details $julian_date "<a href=\"old.tcl?[export_url_vars spam_id]\">$title</a>($status) - <i>$beginning_of_body</i><br>"
}

set next_month_template "(<a href=\"index.tcl?date=\$ansi_date\">next</a>)"
set prev_month_template "(<a href=\"index.tcl?date=\$ansi_date\">prev</a>)"

append pagebody "[calendar_basic_month -calendar_details $calendar_details  -next_month_template $next_month_template -prev_month_template $prev_month_template -date $date]
 
<ul>
<li>
<a href=spam-add.tcl>Post a spam (plain text)</a>
<p>
<li>
<a href=\"spam-add.tcl?html_p=t\">Post a spam (plain text plus HTML/AOL)</a>
<p>
<li>
<a href=\"upload-file.tcl\">Upload a spam from a local file to the drop zone</a>
<p>
<li>
<a href=\"show-daily-spam.tcl\">View/modify automatic  daily spam file settings</a>
<p>
</ul>

<p>

"

append pagebody "
<p>
<h3>Debugging Switches</h3>
<ul>
"

set email_enabled_p [spam_email_sending_p]

if {$email_enabled_p == 1} {
    append pagebody "<li>Spam email sending is enabled. Click here to <a href=\"set-spam-sending.tcl?enable_p=0\">disable</a>"
} else {
    append pagebody "<li>Spam email sending is disabled. Click here to <a href=\"set-spam-sending.tcl?enable_p=1\">enable</a>"
}

set daemon_enabled_p [spam_daemon_active_p]

if {$daemon_enabled_p == 1} {
    append pagebody "<li>Dropzone scanner daemon is enabled. Click here to <a href=\"set-daemon-state.tcl?enable_p=0\">disable</a>"
} else {
    append pagebody "<li>Dropzone scanner daemon is disabled. Click here to <a href=\"set-daemon-state.tcl?enable_p=1\">enable</a>"
}

set bulkmail_enabled_p [spam_use_bulkmail_p]

if {$bulkmail_enabled_p == 1} {
    append pagebody "<li>Sending spam using <b>bulkmail module</b> is enabled. Click here to <a href=\"bulkmail-mailer.tcl?enable_p=0\">switch to use ns_sendmail</a>"
} else {
    append pagebody "<li>Sending spam using <b>ns_sendmail</b> is enabled. Click here to <a href=\"bulkmail-mailer.tcl?enable_p=1\">switch to use bulkmail module</a>"
}

append pagebody "<p><li><a href=send-spam-now.tcl>Force spam daemon to run queue now</a>"

append pagebody "<p><li><a href=/admin/bulkmail/monitor.tcl>Monitor bulkmail threads</a>"

append pagebody "
</ul>    

<a href=/doc/spam.html>Documentation for the spam system is available here.</a>
<p>
<font color=red><a href=stop-spam.html>How to suspend and resume a mailing</a></font>
<p>

[ad_admin_footer]
"

ns_write $pagebody
