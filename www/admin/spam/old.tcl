# www/admin/spam/old.tcl

ad_page_contract {

 Show details of a spam from the database

    @param spam_id id of this spam, index into spam_history table
    @author hqm@arsdigita.com
    @cvs-id old.tcl,v 3.7.2.6 2000/09/22 01:36:06 kevin Exp
} {
    spam_id:integer
}

set user_id [ad_verify_and_get_user_id]


set spam_p [db_0or1row spam_info  "select to_char(sh.begin_send_time,'YYYY-MM-DD HH24:MI:SS') as begin_send_time,
		   to_char(sh.finish_send_time,'YYYY-MM-DD HH24:MI:SS') as finish_time,
		   sh.from_address, 
		   sh.title,
		   sh.body_plain,
		   sh.body_html,
		   sh.body_aol,
		   sh.user_class_description,
		   to_char(sh.send_date,'YYYY-MM-DD HH24:MI:SS') as send_date,
		   to_char(sh.creation_date,'YYYY-MM-DD HH24:MI:SS') as creation_time,
		   sh.n_sent, users.user_id,
		   users.first_names || ' ' || users.last_name as user_name, 
		   users.email,
		   sh.status,
		   sh.last_user_id_sent,
		   to_char(sysdate-sh.begin_send_time) as nmins_running,
		   to_char(sh.finish_send_time-sh.begin_send_time) as nmins_completed,
		   sh.finish_send_time
              from spam_history sh, users
             where sh.creation_user = users.user_id
               and sh.spam_id = :spam_id"]

if { ! $spam_p } {
    ad_return_error "Couldn't find spam" "Could not find an old spam with an id of $spam_id"
    ad_script_abort
}

if {![exists_and_not_null nmins_completed]} {
    set nmins_completed 0
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

if { $nmins_running == 0 || [empty_string_p $nmins_running] || 
     $nmins_completed == 0 || [empty_string_p $nmins_completed] } {
    set n_per_min 0
} else {
    if {![empty_string_p $finish_send_time]} {
	set n_per_min [expr $n_sent / ( $nmins_completed * 24 * 60)]
    } else {
	set n_per_min [expr $n_sent / ( $nmins_running * 24 * 60)]
    }
}

append page_content "[ad_admin_header "$title"]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Spamming"] "Old Spam"]

<hr>

<ul>
<li> requested send date: $send_date
<li> actual send start time: $begin_send_time
<li> finish time: $finish_time
<li> the time now is [db_string pretty_date  "select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') from dual"]
<li> status: $status
<li>number sent:  $n_sent ($n_per_min  msgs/min)
<li>class:  users who $user_class_description
<li>last_user_id_sent: $last_user_id_sent
<li>send from:  \"$from_address\" (admin logged in was <a href=\"/admin/users/one?[export_url_vars user_id]\">$user_name</a> ($email))

<li>subject:  $title
<p>
Set status manually to <tt> 
 <a href=set-spam-status?spam_id=$spam_id&status=cancelled>cancelled</a> 
 ||  <a href=set-spam-status?spam_id=$spam_id&status=hold>hold</a> 
 || <a href=set-spam-status?spam_id=$spam_id&status=sent>sent</a>
 || <a href=set-spam-status?spam_id=$spam_id&status=sending>sending</a>
 || <a href=set-spam-status?spam_id=$spam_id&status=interrupted>interrupted</a>
||  <a href=set-spam-status?spam_id=$spam_id&status=unsent>unsent</a></tt>
<p>
</ul>
<li><a href=spam-edit?spam_id=$spam_id>Edit this message</a>
</ul>
<p>

<table border=1>
<tr><th align=right valign=top>Plain Text Message:</th><td>
<pre>[ns_quotehtml $body_plain]</pre>
</td></tr>

"
if {[info exists body_html] && ![empty_string_p $body_html]} {
    append page_content "<tr><th align=right valign=top>HTML Message:</th>
<td>
$body_html
</td>
</tr>"
}

if {[info exists body_aol] && ![empty_string_p $body_aol]} {
    append page_content "<tr><th align=right valign=top>AOL Message:</th>
<td>
$body_aol
</td>
</tr>"
}

append page_content "
</table>

</blockquote>

</ul>

$cancel_spam_option 
<p>
[ad_admin_footer]
"


doc_return  200 text/html $page_content

