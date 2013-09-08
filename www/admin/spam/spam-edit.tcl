# /admin/spam/spam-edit.tcl

ad_page_contract {

  View/modify status and content of a message
   
  @param spam_id ID of the message in the spam_history table
  @param subject Subject line for message
  @param from_address Value for the From: header of the message
  @param user_class_id An ID of a user class in the user_classes table

    @author hqm@arsdigita.com
    @cvs-id spam-edit.tcl,v 3.3.2.10 2000/09/22 01:36:07 kevin Exp
} {
   spam_id:integer
   {subject ""}
   {from_address ""}
   {user_class_id:integer ""}
}



set user_id [ad_verify_and_get_user_id]


set exception_count 0
set exception_text ""

# Generate the SQL query from the user_class_id, if supplied
if {![empty_string_p $user_class_id]} {
    # we should make a ns_set with just one entry here - user-class-id
    set users_sql_query [ad_user_class_query [ns_getform] [ns_set create]]
    set sql_description [ad_user_class_description [ns_getform]]
    set spam_query [spam_rewrite_user_class_query $users_sql_query]

    set class_name [db_string pretty_user_class_name "select name from user_classes where user_class_id = :user_class_id "]

    if {[catch {db_dml update_user_class_sql "
        UPDATE spam_history
	   SET user_class_description = :sql_description, 
	       user_class_query = :spam_query
	 WHERE spam_id = :spam_id" } errmsg]} { 
	ad_return_error "Ouch!" "The database choked this update:
	<blockquote>
	$errmsg
	</blockquote>
	"
	return
    }
}

if {![empty_string_p $subject]} {
    db_dml update_title "update spam_history set title = :subject where spam_id = :spam_id"
}

if {![empty_string_p $from_address]} {
    db_dml update_from_addr "update spam_history set from_address = :from_address where spam_id = :spam_id"
}

if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set nrows [db_0or1row spam_info  "select to_char(sh.begin_send_time,'YYYY-MM-DD HH24:MI:SS') as begin_send_time,
                   to_char(sh.finish_send_time,'YYYY-MM-DD HH24:MI:SS') as finish_time,
                   sh.from_address,
                   sh.title,
                   sh.body_plain,
                   sh.body_html,
                   sh.body_aol,
                   sh.user_class_description,
                   to_char(sh.send_date,'YYYY-MM-DD') as send_date,
                   to_char(sh.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_time,
                   sh.n_sent,
                   users.user_id,
                   users.first_names || ' ' || users.last_name as user_name,
                   users.email,
                   sh.status,
                   sh.last_user_id_sent,
                   to_char(sysdate-sh.begin_send_time) as nmins_running,
                   to_char(sh.finish_send_time-sh.begin_send_time) as nmins_completed,
                   sh.finish_send_time
              from spam_history sh, users
             where sh.creation_user = users.user_id
                   and sh.spam_id = :spam_id" ]

if { $nrows == 0 } {
    ad_return_error "Couldn't find spam" "Could not find an old spam with an id of $spam_id"
    return
}

if {[string compare $status "unsent"] == 0} {
    set cancel_spam_option "<ul>
    <li>
    <a href=\"cancel-spam?spam_id=$spam_id\">Click here to cancel this spam</a>
    </ul>
    "
} else {
    set cancel_spam_option ""
}

if {[info exists n_sent] && [info exists nmins_running] && [info exists nmins_completed] \
	&& $n_sent  != 0 && $nmins_completed != 0 && $nmins_running != 0} {
    if {![empty_string_p $finish_send_time]} {
	set n_per_min [expr $n_sent / ( $nmins_completed * 24 * 60)]
    } else {
	set n_per_min [expr $n_sent / ( $nmins_running * 24 * 60)]
    }
} else {
    set n_per_min 0
}

append pagebody "[ad_admin_header "Edit Message #$spam_id:  $title"]

<h2>Edit Message #$spam_id: $title</h2>

[ad_admin_context_bar [list "index.tcl" "Spamming"] "Edit Message #$spam_id"]

<hr>

<ul>
<form method=post action=spam-edit>
[export_form_vars spam_id]
<li> Requested send date: [ad_dateentrywidget "send_date" $send_date]

<p>
<li> Status: <b>$status</b>
<br>modify <tt> 
 <a href=set-spam-status?spam_id=$spam_id&status=cancelled>cancelled</a> 
 ||  <a href=set-spam-status?spam_id=$spam_id&status=hold>hold</a> 
 || <a href=set-spam-status?spam_id=$spam_id&status=sent>sent</a>
 || <a href=set-spam-status?spam_id=$spam_id&status=sending>sending</a>
 || <a href=set-spam-status?spam_id=$spam_id&status=interrupted>interrupted</a>
||  <a href=set-spam-status?spam_id=$spam_id&status=unsent>unsent</a></tt>
<p>
<li> User class:  users who $user_class_description
<p>
(choose new user class) <select name=user_class_id>
<option value=\"\"></option>[db_html_select_value_options user_class_select_options "select user_class_id, name from user_classes order by name"]
</select> 
<p>
<li>Send from:  <input name=from_address value=\"[ns_quotehtml $from_address]\"> (admin logged in was <a href=\"/admin/users/one?[export_url_vars user_id]\">$user_name</a> ($email)) 

<p>
<li>Subject:  <input name=subject value=\"[philg_quote_double_quotes $title]\"> 
<br>
<center><input type=submit value=Modify></center>
</ul>
</form>
<p>
"

if {[string compare $status "hold"] == 0} {
    append pagebody "<ul><li>
    <a href=set-spam-status?spam_id=$spam_id&status=unsent>activate this message to be sent</a>
    </ul><p>
    "
} else {

}

append pagebody "
 <form enctype=multipart/form-data method=POST action=\"upload-file-to-spam\">
<blockquote>
Upload a content part file to the spam message
<table border=0>
<tr><th align=right>Content part type</th><td><select name=data_type>
<option value=plain>Plain Text Part</option>
<option value=html>HTML Part</option>
<option value=aol>AOL (html) Part</option>
</select></td></tr>
<tr><th align=right> Local file:</th><td> <input name=clientfile type=file>
<br>
<font size=-1>Use the \"Browse...\" button to locate your file, then click \"Open\".</font></td></tr>
</table>
[export_form_vars spam_id]
<center><input name=submit type=submit value=Upload></center>
</form>
<p>

<table border=1>
<tr><th align=right valign=top>Plain Text Message:</th><td>
<pre>[ns_quotehtml $body_plain]</pre>
</td></tr>

<tr><th align=right valign=top>HTML Message:<br></th>
<td>
$body_html
</td>
</tr>
<tr><th align=right valign=top>AOL Message:</th><td>
$body_aol
</td>
</tr>

</table>

</blockquote>

</ul>

$cancel_spam_option 
<p>
[ad_admin_footer]
"

db_release_unused_handles

# serve the page

doc_return  200 text/html $pagebody

