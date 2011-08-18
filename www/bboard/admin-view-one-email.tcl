# $Id: admin-view-one-email.tcl,v 3.0 2000/02/06 03:33:33 ron Exp $
# look at the postings for one email address (i.e., one user)

set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, email

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}



# cookie checks out; user is authorized



ReturnHeaders

ns_write "<html>
<head>
<title>Postings by $email in the $topic forum</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Postings by $email in the $topic forum</h2>

(<a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">main admin page</a>)

<hr>

<form method=post action=admin-bulk-delete-by-email-or-ip.tcl>
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
<input type=hidden name=email value=\"$email\">
<ul>

"

set selection [ns_db select $db "select one_line, sort_key, msg_id, posting_time as posting_date
from bboard, users
where  bboard.user_id = users.user_id
and topic_id=$topic_id
and email = '$QQemail'
order by sort_key desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    ns_write "<table width=85%>
<tr>
<td>
<li><a href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$thread_start_msg_id\">$one_line</a> ($posting_date)
<td align=right>
<input type=checkbox name=deletion_ids value=\"$msg_id\">
</tr>
</table>
"
}

ns_write "</ul>

<center>
<input type=submit value=\"delete marked messages\">
</form>
</center>

[bboard_footer]
"
