# $Id: old.tcl,v 3.1.2.2 2000/04/04 15:09:12 carsten Exp $
# old.tcl
# 
# hqm@arsdigita.com
#
# Show details of a spam from the database

set_the_usual_form_variables

# spam_id

set db [ns_db gethandle] 

set selection [ns_db 0or1row $db "select to_char(sh.begin_send_time,'YYYY-MM-DD HH24:MI:SS') as begin_send_time,to_char(sh.finish_send_time,'YYYY-MM-DD HH24:MI:SS') as finish_time, sh.from_address, sh.title, sh.body_plain, sh.body_html, sh.body_aol, sh.user_class_description, to_char(sh.send_date,'YYYY-MM-DD HH24:MI:SS') as send_date, to_char(sh.creation_date,'YYYY-MM-DD HH24:MI:SS') as creation_time, sh.n_sent, users.user_id, users.first_names || ' ' || users.last_name as user_name, users.email, sh.status, sh.last_user_id_sent, to_char(sysdate-sh.begin_send_time) as nmins_running, to_char(sh.finish_send_time-sh.begin_send_time) as nmins_completed, sh.finish_send_time
from spam_history sh, users
where sh.creation_user = users.user_id
and sh.spam_id = $spam_id"]

if { $selection == "" } {
    ad_return_error "Couldn't find spam" "Could not find an old spam with an id of $spam_id"
    return
}

set_variables_after_query

if {[string compare $status "unsent"] == 0} {
set cancel_spam_option "<ul>
<li>
<a href=\"cancel-spam.tcl?spam_id=$spam_id\">Click here to cancel this spam</a>
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


ReturnHeaders

ns_write "[ad_admin_header "$title"]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Spamming"] "Old Spam"]

<hr>

<ul>
<li> requested send date: $send_date
<li> actual send start time: $begin_send_time
<li> finish time: $finish_time
<li> the time now is [database_to_tcl_string $db "select to_char(sysdate,'YYYY-MM-DD HH24:MI:SS') from dual"]
<li> status: $status
<li>number sent:  $n_sent ($n_per_min  msgs/min)
<li>class:  users who $user_class_description
<li>last_user_id_sent: $last_user_id_sent
<li>send from:  \"$from_address\" (admin logged in was <a href=\"/admin/users/one.tcl?[export_url_vars user_id]\">$user_name</a> ($email))

<li>subject:  $title
</ul>
Set status manually to <tt> <a href=set-spam-status.tcl?spam_id=$spam_id&status=sent>sent</a>
 || <a href=set-spam-status.tcl?spam_id=$spam_id&status=sending>sending</a>
 || <a href=set-spam-status.tcl?spam_id=$spam_id&status=interrupted>interrupted</a>
||  <a href=set-spam-status.tcl?spam_id=$spam_id&status=unsent>unsent</a></tt>
<p>


<table border=1>
<tr><th align=right valign=top>Plain Text Message:</th><td>
<pre>[ns_quotehtml $body_plain]</pre>
</td></tr>



"
if {[info exists body_html] && ![empty_string_p $body_html]} {
    ns_write "<tr><th align=right valign=top>HTML Message:</th>
<td>
$body_html
</td>
</tr>"
}

if {[info exists body_aol] && ![empty_string_p $body_aol]} {
    ns_write "<tr><th align=right valign=top>AOL Message:</th>
<td>
$body_aol
</td>
</tr>"
}


ns_write "
</table>

</blockquote>

</ul>

$cancel_spam_option 
<p>
[ad_admin_footer]
"
