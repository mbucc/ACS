# $Id: spam.tcl,v 3.2 2000/03/08 08:56:44 hqm Exp $
# spam.tcl
#
# hqm@arsdigita.com
#
# Queues an outgoing spam message to a group of users,
# by adding it to the spam_history table

set_the_usual_form_variables

ns_log Notice "spam.tcl: entering page"

# spam_id, from_address, subject, 
# message (optionally message_html, message_aol)
# maybe send_date
# from_file_p
# template_p
#
# users_sql_query     The SQL needed to get the list of target users
# users_description   English descritpion of target users

set admin_user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# Strip all ^M's out of any itneractively entered text message.
# This is because Windows browsers insist on inserting CRLF at
# the end of each line of a TEXTAREA.
if {[info exists message]} {
    regsub -all "\r" $message "" message_stripped 
}

if {[info exists from_file_p] && [string compare $from_file_p "t"] == 0} {
    set message [get_spam_from_filesystem "plain"]
    set message_html [get_spam_from_filesystem "html"]
    set message_aol [get_spam_from_filesystem "aol"]
}

if {[info exists template_p] && [string match $template_p "t"]} {
} else {
    set template_p "f"
}

if {![info exists send_date]} {
    set send_date ""
}

if {![info exists message_html]} {
    set message_html ""
}

if {![info exists message_aol]} {
    set message_aol ""
}

set exception_count 0
set exception_text ""

if {[empty_string_p $subject] && [empty_string_p $message_stripped] && [empty_string_p $message_html] && [empty_string_p $message_aol]} {
    incr exception_count
    append exception_text "<li>The contents of your message and subject line is the empty string. You must send something in the message body"
}


if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [ns_db gethandle]

if [catch { ns_ora clob_dml $db "insert into spam_history
(spam_id, template_p, from_address, title, body_plain, body_html, body_aol, user_class_description, user_class_query, send_date, creation_date, creation_user, creation_ip_address, status)
values
($spam_id, '$template_p', '$QQfrom_address', '$QQsubject', empty_clob(),empty_clob(),empty_clob(), '[DoubleApos $users_description]', [ns_dbquotevalue $users_sql_query], nvl(to_date('$send_date', 'YYYY-MM-DD HH24:MI:SS'), sysdate), sysdate, $admin_user_id, '[DoubleApos [ns_conn peeraddr]]', 'unsent')
returning body_plain, body_html, body_aol into :1, :2, :3" $message_stripped $message_html $message_aol } errmsg] {
    # choked; let's see if it is because 
    if { [database_to_tcl_string $db "select count(*) from spam_history where spam_id = $spam_id"] > 0 } {
	ns_return 200 text/html "[ad_admin_header "Double Click?"]

<h2>Double Click?</h2>

<hr>

This spam has already been sent.  Perhaps you double clicked?  In any 
case, you can check the progress of this spam on
<a href=\"old.tcl?[export_url_vars spam_id]\">the history page</a>.

[ad_admin_footer]"
    } else {
	ad_return_error "Ouch!" "The database choked on your insert:
<blockquote>
$errmsg
</blockquote>
"
    }
    return
}


ReturnHeaders 

append pagebody "[ad_admin_header "Spamming users who $users_description"]

<h2>Spamming Users</h2>

[ad_admin_context_bar [list "index.tcl" "Spamming"] "Spam Execution"]

<hr>

Class description:  users who $users_description.

<P>

Query to be used:

<blockquote><pre>
$users_sql_query
</pre></blockquote>

<p>

Message to be sent:

<ul>
<li>from: $from_address
<li>subject:  $subject
<li>send on:  $send_date
<li>body: <blockquote><pre>$message_stripped</pre></blockquote>

</ul>

"


append pagebody "


Queued for delivery by the spam sending daemon.
<p>

[ad_admin_footer]
"
ns_write $pagebody

ns_conn close
ns_db releasehandle $db


ns_log Notice "spam.tcl: calling spam queue sweeper $spam_id now from interactive spam.tcl page"
send_scheduled_spam_messages
ns_log Notice "spam.tcl: spam $spam_id sent"


