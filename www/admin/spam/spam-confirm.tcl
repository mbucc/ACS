# www/admin/spam/spam-confirm.tcl

ad_page_contract {

 Allow user to confirm the outgoing spam before queuing it for delivery.
   
   @param spam_id id of the message
   @param subject  subject line for header
   @param from_address  from address for header
   @param message text of the message
   @param message_html html version of the message
   @param message_aol aol_html dialect version of the message
   @param send_date when to schedule the message for delivery
   @param from_file_p flag to get message content from filesystem rather than from page vars
   @param users_sql_query custom SQL query to generate the list of target users
   @param users_description English description of target list of user
   @param user_class_id An id of a user-class, mutually exclusive with users_sql_query
   @param template_p If t, perform Tcl substitution on the message body

    @author hqm@arsdigita.com
    @cvs-id spam-confirm.tcl,v 3.9.2.10 2001/01/12 00:15:16 khy Exp
} {
   spam_id:integer,notnull,verify
   subject
   from_address
   message
   {message_html ""}
   {message_aol ""}
   {send_date ""}
   {from_file_p f}
   {users_sql_query ""}
   {users_description ""}
   {user_class_id:integer ""}
   {template_p f}
}






set admin_user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

if {[string compare $from_file_p "t"] == 0} {
    set message [get_spam_from_filesystem "plain"]
    set message_html [get_spam_from_filesystem "html"]
    set message_aol [get_spam_from_filesystem "aol"]
}

set message [spam_wrap_text $message 80]

set exception_count 0
set exception_text ""

if {[catch {ns_dbformvalue [ns_conn form] send_date datetime send_date} errmsg]} {
    incr exception_count
    append exception_text "<li>Please make sure your date is valid."
}

# Generate the SQL query from the user_class_id, if supplied
if {![empty_string_p $user_class_id]} {
    set arg_set [ad_tcl_vars_to_ns_set user_class_id]
    set users_sql_query [ad_user_class_query $arg_set]
    set class_name [db_string user_class_name "select name from user_classes where user_class_id = :user_class_id "]

    set sql_description [db_string user_class_query_description "select sql_description from user_classes where user_class_id = :user_class_id "]
    set users_description "$class_name: $sql_description"
}

if { ![philg_email_valid_p $from_address] } {
    incr exception_count
    append exception_text "<li>The From address is invalid."
}

if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ns_dbformvalue [ns_conn form] send_date datetime send_date

if {[info exists template_p] && [string match $template_p "t"]} {
   set template_pretty "Yes"
} else {
    set template_p "f"
    set template_pretty "No" 
}

append pagebody "[ad_admin_header "Confirm sending spam"]

[ad_admin_context_bar [list "index.tcl" "Spam"] "confirm sending a spam"]

<hr>

<h2>Confirm Sending Spam</h2>

The following spam will be queued for delivery:

<p>
"

# strips ctrl-m's, makes linebreaks at >= 80 cols when possible, without
# destroying urls or other long strings
set message [spam_wrap_text $message 80]

append pagebody "

<form method=POST action=\"/admin/spam/spam\">
[export_form_vars subject from_address message message_html message_aol send_date from_file_p users_sql_query users_description user_class_id template_p]

[export_form_vars -sign spam_id]

<blockquote>
<table border=1>
<tr><th align=right>User&nbsp;Class:</th><td> $users_description
</td></tr>
<tr><th align=right>Date:</th><td> $send_date </td></tr>

<tr><th align=right>From:</th><td>$from_address</td></tr>
<tr><th align=right>Template?</th><td>$template_pretty</td></tr>

<tr><th align=right>Subject:</th><td>$subject</td></tr>

<tr><th align=right valign=top>Plain Text Message:</th><td>
<pre>[ns_quotehtml $message]</pre>
</td></tr>

"
if {[info exists message_html] && ![empty_string_p $message_html]} {
    append pagebody "<tr><th align=right valign=top>HTML Message:</th>
<td>
$message_html
</td>
</tr>"
}

if {[info exists message_aol] && ![empty_string_p $message_aol]} {
    append pagebody "<tr><th align=right valign=top>AOL Message:</th>
<td>
$message_aol
</td>
</tr>"
}

append pagebody "
</table>

</blockquote>
<center>
<input type=submit value=\"Send Spam\">

</center>

</form>
<p>

<i>The SQL query will be</i>
<pre>$users_sql_query</pre>
"

set count_users_query "select count(*) from ($users_sql_query)" 
set total_users [db_string recipient_count $count_users_query]

append pagebody "
and will send email to $total_users users.
[ad_admin_footer]"



doc_return  200 text/html $pagebody










