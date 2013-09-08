# spam.tcl,v 3.10.2.7 2000/09/22 01:37:42 kevin Exp
# spam.tcl
#
# hqm@arsdigita.com
#
# Queues an outgoing spam message to a group of users,
# by adding it to the spam_history table

# spam_id, from_address, subject, 
# message (optionally message_html, message_aol)
# maybe send_date
# from_file_p
# template_p
#
#maybe create_comment_p, event_id

ad_page_contract {
    Confirms sending spam.

    @param spam_id id of the spam to send
    @param from_address email address the spam is from
    @param subject the email's subject
    @param message email message
    @param message_html email message in html format
    @param message_aol email message in aol format
    @param send_date when to send the email
    @param from_file_p is this email from a file
    @param users_sql_query sql query describing which users to spam
    @param users_description description of the users to spam
    @param template_p is this email a tcl template

    @param create_comment_p should this spam create a registration comment
    @param event_id which event to comment about when spamming a selected event

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id spam.tcl,v 3.10.2.7 2000/09/22 01:37:42 kevin Exp
} {
    {spam_id:integer,notnull}
    {from_address:notnull}
    {subject:trim [db_null]}
    {message:html,trim,optional}
    {message_html:html,trim,optional}
    {message_aol:html,trim,optional}
    {send_date:optional}
    {from_file_p:optional}
    {users_sql_query}
    {users_description:optional}
    {template_p:optional}

    {create_comment_p:optional}
    {event_id:integer,optional}
}


ns_log Notice "spam.tcl: entering page"

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


# Generate the SQL query from the user_class_id, if supplied
if {[info exists user_class_id] && ![empty_string_p $user_class_id]} {
    set users_sql_query [ad_user_class_query [ns_getform]]
    set class_name [db_string evnt_spam_sel_class_name "select name from user_classes where user_class_id = :user_class_id "]

    set sql_description [db_string evnt_spam_sel_sql_desc "select sql_description from user_classes where user_class_id = :user_class_id "]
    set users_description "$class_name: $sql_description"
}

#set spam_query [spam_rewrite_user_class_query $users_sql_query]
set spam_query $users_sql_query

if [catch { 
    spam_post_new_spam_message -spam_id $spam_id -template_p $template_p \
    -from_address $from_address \
    -title $subject \
    -body_plain $message_stripped \
    -body_html $message_html \
    -body_aol $message_aol \
    -target_users_description $users_description \
    -target_users_query $spam_query \
    -send_date $send_date \
    -creation_user $admin_user_id
} errmsg] {
    # choked; let's see if it is because 
    if { [db_string evnt_spam_dbl_click "select count(*) from spam_history where spam_id = $spam_id"] > 0 } {
	doc_return  200 text/html "[ad_admin_header "Double Click?"]

<h2>Double Click?</h2>

<hr>

This spam has already been sent.  Perhaps you double clicked?  In any 
case, you can check the progress of this spam on
<a href=\"old?[export_url_vars spam_id]\">the history page</a>.

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

#Perhaps create a comment for the users' registrations
#Note that this only makes sense if the spam is sent immediately.
#If the spam were sent in the future, then it could be sent to
#registrants whose registrations weren't marked with this
#comment because the registrations took place after these comments
#were created but before the spam was sent.  Also note that
#there still could be a few people who register in the short time
#between the comments below are created and the spam is sent.  In that
#case, these users' registrations won't be marked with comments
#either.

if {[exists_and_not_null create_comment_p] && [exists_and_not_null event_id] && $create_comment_p != 0} {
    
    db_foreach evnt_spam_create_comment "select
    r.reg_id, r.comments
    from events_reg_not_canceled r, events_prices p
    where p.event_id = $event_id
    and r.price_id = p.price_id
    and r.user_id in
    (select distinct u.user_id
    from users u, ($users_sql_query) sql_query
    where u.email = sql_query.email)
    " {
	append comments "\n------\nSent the following e-mail to this registrant on $send_date:\n\n$message_stripped\n------"
	
	db_dml evnt_spam_create_comment "update events_registrations
	set comments = :comments
	where reg_id = :reg_id"
    }
}    

append pagebody "[ad_admin_header "Spamming $users_description"]

<h2>Spamming Users</h2>
[ad_context_bar_ws [list "../index.tcl" "Events Administration"]  "Spam"]

<hr>

Class description:  $users_description.

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
db_release_unused_handles

doc_return 200 text/html $pagebody

ns_conn close

ns_log Notice "spam.tcl: calling spam queue sweeper $spam_id now from interactive spam.tcl page"
send_scheduled_spam_messages
ns_log Notice "spam.tcl: spam $spam_id sent"

