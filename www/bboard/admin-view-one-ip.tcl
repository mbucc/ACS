# /www/bboard/admin-view-one-ip.tcl
ad_page_contract {
    look at the postings for one email address (i.e., one user)

    @cvs-id admin-view-one-ip.tcl,v 3.2.2.3 2000/09/22 01:36:47 kevin Exp
} {
    topic:notnull
    originating_ip:notnull
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

# cookie checks out; user is authorized

append page_content "
[bboard_header "Postings from $originating_ip in the $topic forum"]

<h2>Postings from $originating_ip</h2>

in the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic</a> forum 

<hr>

Doing a reverse DNS now:  $originating_ip maps to ...  [ns_hostbyaddr $originating_ip]

<P>

(note: if you just get the number again, that means the hostname could
not be found.)

<P>

<form method=post action=admin-bulk-delete-by-email-or-ip>
[export_form_vars topic topic_id originating_ip]

<ul>

"

db_foreach ip_messages "
select one_line, 
       sort_key, 
       msg_id, 
       to_char(posting_time,'YYYY-MM-DD HH24:MI:SS') as posting_date, 
       email, 
       first_names || ' ' || last_name as name
from   bboard, users
where  bboard.user_id = users.user_id
and    topic_id = :topic_id
and    originating_ip = :originating_ip
order by sort_key desc" {

    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    append page_content "<table width=85%>
<tr>
<td>
<li>$name (<a href=\"mailto:$email\">$email</a>) on $posting_date: <a href=\"admin-q-and-a-fetch-msg?msg_id=$thread_start_msg_id\">$one_line</a>
<td align=right>
<input type=checkbox name=deletion_ids value=\"$msg_id\">
</tr>
</table>
"
}

append page_content "</ul>

<center>
<input type=submit value=\"delete marked messages\">
</form>
</center>

[bboard_footer]

"


doc_return  200 text/html $page_content