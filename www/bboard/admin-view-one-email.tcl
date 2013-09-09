# /www/bboard/admin-view-one-email.tcl
ad_page_contract {
    look at the postings for one email address (i.e., one user)

    @cvs-id admin-view-one-email.tcl,v 3.2.2.3 2000/09/22 01:36:47 kevin Exp
} {
    topic:notnull
    email:notnull
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
[bboard_header "Postings by $email in the $topic forum"]

<h2>Postings by $email in the $topic forum</h2>

(<a href=\"admin-home?[export_url_vars topic topic_id]\">main admin page</a>)

<hr>

<form method=post action=admin-bulk-delete-by-email-or-ip>
[export_form_vars topic topic_id email]
<ul>

"

db_foreach email_messages "
select one_line, sort_key, msg_id, posting_time as posting_date
from   bboard, users
where  bboard.user_id = users.user_id
and    topic_id = :topic_id
and    email = :email
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
<li><a href=\"admin-q-and-a-fetch-msg?msg_id=$thread_start_msg_id\">$one_line</a> ($posting_date)
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