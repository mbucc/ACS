# www/admin/spam/spam-create-2.tcl

ad_page_contract {

 Create a new spam, to be filled in with data at a later point
 (put it in "hold" state)


     @param spam_id id of this spam
     @param from_address sender email for header
     @param subject subject line
     @param user_class_id target users class
     @param send_date date to send this spam


    @author hqm@arsdigita.com
    @cvs-id spam-create-2.tcl,v 3.3.2.9 2001/01/12 00:07:41 khy Exp
} {
    spam_id:integer,notnull,verify
    from_address
    subject
    user_class_id:integer,notnull
    
}


set admin_user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


# Generate the SQL query from the user_class_id
set arg_set [ad_tcl_vars_to_ns_set user_class_id]
set spam_query [ad_user_class_query $arg_set]
set sql_description [ad_user_class_description $arg_set]

set exception_count 0
set exception_text ""

if [catch {ns_dbformvalue [ns_conn form] send_date date send_date} errmsg] {
    incr exception_count
    append exception_text "<li>Please make sure your date is valid."
}	   

if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if {[catch {spam_post_new_spam_message \
	-spam_id $spam_id \
	-from_address $from_address \
	-title $subject \
	-target_users_description $sql_description \
	-target_users_query $user_class_id \
	-send_date $send_date \
	-creation_user $admin_user_id \
	-status "hold"
} errmsg]} {
    # choked; let's see if it is because 
    if { [db_string duplicate_spam_check "select count(*) from spam_history where spam_id = :spam_id"] > 0 } {
	doc_return  200 text/html "[ad_admin_header "Double Click?"]

<h2>Double Click?</h2>

<hr>

This spam has already been created.  Perhaps you double clicked?  In any 
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

append pagebody "[ad_admin_header "New Message Created"]

<h2>New Message Created</h2>

[ad_admin_context_bar [list "index.tcl" "Spamming"] "New Message"]

<hr>

A new spam message has been created, and is in the <b>hold</b> state until
you have filled in the message content fields. You can edit the message from <a href=spam-edit?[export_url_vars spam_id]>here</a>.
<p>

Class description:  users who $sql_description.

<P>

Query to be used to select target users:

<blockquote><pre>
$user_class_id
</pre></blockquote>

<p>

Message to be sent:

<ul>
<li>from: $from_address
<li>subject:  $subject
<li>message content: <i>not yet specified</i>

</ul>


<p>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $pagebody


