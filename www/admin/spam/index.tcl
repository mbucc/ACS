# www/admin/spam/index.tcl
 
ad_page_contract {
    View/Edit/Create email messages

   
    @param view_date <em>optional</em> Display scheduled spams within a one month window, defaults to current date.
    @param view filter messages by creator. Legal values are mine,all
    @author hqm@arsdigita.com
    @cvs-id index.tcl,v 3.13.2.9 2000/09/22 01:36:06 kevin Exp
} {
    { view_date {[db_string sysdate "select sysdate from dual"]}}
    { view "all" }
}

append pagebody "[ad_admin_header "Spamming"]

<h2>Spamming</h2>

[ad_admin_context_bar "Spamming"]


<hr>

<p>
"



if {[empty_string_p $view_date]} {
    set view_date
}

append pagebody "<center>
<h4>The time is now [db_string "pretty_date" "select to_char(sysdate,'MM-DD-YYYY HH24:MI:SS') from dual"]</h4>
</center>
"



if {[string compare "mine" $view] == 0} {
    set filter_clause " and creation_user = [ad_verify_and_get_user_id] "
} else {
    set filter_clause ""
}

set dimensional {
    {view "View" all {
        {mine "mine" {view_filter " and creation_user = [ad_verify_and_get_user_id] "}}
        {all "all" {}}
    }
}
}

append pagebody [ad_dimensional $dimensional]



# get all the spams for this month 
# this query goes a little beyond for simplicity

set calendar_details [ns_set create calendar_details]

set count 0
db_foreach "this_months_spam" "
   select sh.spam_id, 
          sh.title,
	  sh.status,
	  sh.n_sent,
	  dbms_lob.substr(sh.body_plain,100,1) as beginning_of_body, 
	  sh.user_class_description, 
	  sh.send_date, 
	  to_char(send_date,'J') as julian_date,
	  users.user_id, users.first_names || ' ' || users.last_name as user_name, 
	  users.email
     from spam_history sh, users
    where sh.creation_user = users.user_id
          and send_date  > to_date(:view_date,'yyyy-mm-dd') - 31 
          and send_date  < to_date(:view_date,'yyyy-mm-dd') + 31 
          $filter_clause
    order by send_date desc" -bind [list view_date $view_date view_date $view_date] {
	incr count
	ns_set put $calendar_details $julian_date "<a href=\"old?[export_url_vars spam_id]\">#$spam_id: $title</a><br>status: <b>$status</b><br><small>$n_sent sent</small><hr width=30>"
}

set next_month_template "(<a href=\"index?date=\$ansi_date\">next</a>)"
set prev_month_template "(<a href=\"index?date=\$ansi_date\">prev</a>)"

append pagebody "[calendar_basic_month -calendar_details $calendar_details  -next_month_template $next_month_template -prev_month_template $prev_month_template -date $view_date]
 
<ul>
<li>
<a href=spam-create>Create a new blank message</a> (Can be filled with data and sent in separate step)
<p>
<li>
<a href=spam-add>Post a spam (plain text)</a>
<p>
<li>
<a href=\"spam-add?html_p=t\">Post a spam (plain text plus HTML/AOL)</a>
<p>
<li>
<a href=\"upload-file\">Upload a spam from a local file to the drop zone</a>
<p>
<li>
<a href=\"show-daily-spam\">View/modify automatic  daily spam file settings</a>
<p>
</ul>
<p>
<p>
"

append pagebody "
<p>
<h3>Debugging Switches</h3>
<ul>
"

set email_enabled_p [spam_email_sending_p]

if {$email_enabled_p == 1} {
    append pagebody "<li>Spam email sending is enabled. Click here to <a href=\"set-spam-sending?enable_p=0\">disable</a>"
} else {
    append pagebody "<li>Spam email sending is disabled. Click here to <a href=\"set-spam-sending?enable_p=1\">enable</a>"
}

set daemon_enabled_p [spam_daemon_active_p]

if {$daemon_enabled_p == 1} {
    append pagebody "<li>Dropzone scanner daemon is enabled. Click here to <a href=\"set-daemon-state?enable_p=0\">disable</a>"
} else {
    append pagebody "<li>Dropzone scanner daemon is disabled. Click here to <a href=\"set-daemon-state?enable_p=1\">enable</a>"
}

set bulkmail_enabled_p [spam_use_bulkmail_p]

if {$bulkmail_enabled_p == 1} {
    append pagebody "<li>Sending spam using <b>bulkmail module</b> is enabled. Click here to <a href=\"bulkmail-mailer?enable_p=0\">switch to use ns_sendmail</a>"
} else {
    append pagebody "<li>Sending spam using <b>ns_sendmail</b> is enabled. Click here to <a href=\"bulkmail-mailer?enable_p=1\">switch to use bulkmail module</a>"
}

append pagebody "<p><li><a href=send-spam-now>Force spam daemon to run queue now</a>"

append pagebody "<p><li><a href=/admin/bulkmail/monitor>Monitor bulkmail threads</a>"

append pagebody "
</ul>    

<a href=/doc/spam>Documentation for the spam system is available here.</a>
<p>
<font color=red><a href=stop-spam>How to suspend and resume a mailing</a></font>
<p>

[ad_admin_footer]
"


doc_return  200 text/html $pagebody

