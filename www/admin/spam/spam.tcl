# www/admin/spam/spam.tcl

ad_page_contract {

 Queues an outgoing spam message to a group of users,
 by adding it to the spam_history table

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
    @cvs-id spam.tcl,v 3.5.2.9 2001/01/12 00:15:41 khy Exp
} {
   spam_id:integer,verify
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
    set class_name [db_string user_class_name "
    select name from user_classes where user_class_id = :user_class_id "]

    set sql_description [db_string user_class_description_pretty "select sql_description from user_classes where user_class_id = :user_class_id "]
    set users_description "$class_name: $sql_description"
}

set spam_query [spam_rewrite_user_class_query $users_sql_query]

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
    if { [db_string duplicate_spam_submit "select count(*) from spam_history where spam_id = :spam_id"] > 0 } {
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

db_release_unused_handles
doc_return 200 text/html $pagebody

ns_log Notice "spam.tcl: calling spam queue sweeper $spam_id now from interactive spam.tcl page"
send_scheduled_spam_messages
ns_log Notice "spam.tcl: spam $spam_id sent"

