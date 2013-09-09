# spam-confirm.tcl,v 1.1.2.2 2000/02/03 09:50:02 ron Exp
# File: events/admin/spam-confirm.tcl
# Creator: hqm@arsdigita.com
#
# A good thing to do before sending out 100,000 emails:
# ask user to confirm the outgoing spam before queuing it.
#####

ad_page_contract {
    Confirms sending spam.

    @param spam_id id of the spam to send
    @param from_address email address the spam is from
    @param subject the email's subject
    @param message email message
    @param from_file_p is this email from a file
    @param users_sql_query sql query describing which users to spam
    @param users_description description of the users to spam
    @param template_p is this email a tcl template

    @param create_comment_p should this spam create a registration comment
    @param event_id which event to comment about when spamming a selected event

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id spam-confirm.tcl,v 3.7.6.8 2000/09/22 01:37:41 kevin Exp
} {
    {spam_id:integer,notnull}
    {from_address:trim,notnull}
    {subject:trim,notnull}
    {message:html,trim,notnull}
    {message_html:html,optional}
    {from_file_p:optional}
    {users_sql_query}
    {users_description:optional}
    {template_p:optional}

    {create_comment_p:optional}
    {event_id:integer,optional}
}

# spam_id, from_address, subject, send_date, message
# 
# maybe: message_html
#        from_file_p         If == 't', get message texts from default 
#                filesystem location 
#        users_sql_query     The SQL needed to get the list of target users
#        users_description   English descritpion of target users
#
#  or else user_class_id, which can be passed to ad_user_class_query to
#  generate a SQL query.
#
# maybe: template_p          If == 't', then run subst on the message 
#           subject and body.  A scary prospect, but spam can only be 
#           created by site admins anyhow.  (seems to be disabled here)

#maybe create_comment_p & event_id

set admin_user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

if {[info exists from_file_p] && [string compare $from_file_p "t"] == 0} {
    set message [get_spam_from_filesystem "plain"]
    set message_html [get_spam_from_filesystem "html"]
    set message_aol  [get_spam_from_filesystem "aol"]
}

set exception_count 0
set exception_text ""

if {[catch {ns_dbformvalue [ns_conn form] send_date datetime send_date} errmsg]} {
    incr exception_count
    append exception_text "<li>Please make sure your date is valid."
}

if {[exists_and_not_null create_comment_p]} {
    if {$create_comment_p != 0 && ![exists_and_not_null event_id]} {
	incr exception_count
	append exception_text "<li>This page came in without an event_id"
    }
}

if {[empty_string_p $subject]} {
    incr exception_count
    append exception_text "<li>Please enter a subject"
}

if {[empty_string_p $message]} {
    incr exception_count
    append exception_text "<li>Please enter a message."
}


if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ns_dbformvalue [ns_conn form] send_date datetime send_date

if {[info exists template_p] && [string match $template_p "t"]} {
} else { 
    set template_p "f" 
}

## Begin to return the page...

# Wrap message text properly
set message [spam_wrap_text $message 80]

append pagebody "[ad_admin_header "Confirm sending spam"]
<h2>Confirm Sending Spam</h2>
[ad_context_bar_ws [list "../index.tcl" "Events Administration"]  "Confirm Spam"]

<hr>

The following spam will be queued for delivery:
<p>
"

append pagebody "
<form method=POST action=\"spam\">

<blockquote>
<table border=1>

</td></tr>
<tr><th align=right>Date:</th><td> $send_date </td></tr>

<tr><th align=right>From:</th><td>$from_address</td></tr>
<tr><th align=right>Subject:</th><td>$subject</td></tr>
<tr><th align=right valign=top>Plain Text Message:</th><td>
<pre>[ns_quotehtml $message]</pre>
</td></tr>
"

if {[info exists message_html] && ![empty_string_p $message_html]} {
    append pagebody "
<tr><th align=right valign=top>HTML Message:</th> 
 <td> $message_html </td>
</tr> "
}

if {[info exists message_aol] && ![empty_string_p $message_aol]} {
    append pagebody "
<tr><th align=right valign=top>AOL Message:</th>
 <td> $message_aol </td>
</tr> "
}

append pagebody " </table> </blockquote> "

set count_users_query "select count(*) from ($users_sql_query)"
set total_users [db_string evnt_spam_confirm_count $count_users_query]

append pagebody "
You will send email to $total_users users.
<p>
<center> <input type=submit value=\"Send Spam\"> </center>

[export_form_vars users_sql_query spam_id from_address subject message message_html message_aol send_date template_p users_description create_comment_p event_id]
</form>
[ad_footer]"

## clean up, return the page.



doc_return  200 text/html $pagebody

##### EOF 
