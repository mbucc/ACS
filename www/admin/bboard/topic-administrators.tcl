# $Id: topic-administrators.tcl,v 3.1 2000/02/28 15:52:16 michael Exp $
set_the_usual_form_variables

# topic, topic_id

ReturnHeaders
ns_write "[ad_admin_header "[ad_system_name] $topic administrators"]

<h2>Administrators for $topic</h2>

[ad_admin_context_bar [list "index.tcl" "BBoard Hyper-Administration"] [list "administer.tcl?[export_url_vars topic]" "One Bboard"] Administrators]

<hr>
"

set db [ns_db gethandle]

set selection [ns_db 1row $db "select users.user_id, first_names, last_name from
bboard_topics, users
where bboard_topics.primary_maintainer_id = users.user_id
and topic = '$QQtopic'"]

set_variables_after_query
ns_write "
<p>
The primary maintainer is <A href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name.</a>
<p>
Other maintainers.
<ul>"


set admin_group_id [ad_administration_group_id $db "bboard" $topic_id]

set selection [ns_db select $db "select distinct u.user_id, u.first_names, u.last_name
from users u, user_group_map ugm
where ugm.user_id = u.user_id
and ugm.group_id = $admin_group_id
order by u.last_name asc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a>-<a href=\"administrator-delete.tcl?[export_url_vars topic topic_id admin_group_id user_id]\">Remove</a>"
}

ns_write "
</ul>
<h3>Add Administrator</h3>
<form action=\"/user-search.tcl\" method=post>
<input type=hidden name=target value=\"/admin/bboard/administrator-add.tcl\">
<input type=hidden name=passthrough value=\"topic topic_id\">
<input type=hidden name=custom_title value=\"Choose a Member to Administrate $topic\">
<input type=hidden name=topic value=\"$topic\">
<input type=hidden name=topic_id value=\"$topic_id\">
Search for a user to add to the administration list.<br>
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<p>
<center>
<input type=submit name=submit value=\"Find Administrator\">
</center>
</form>
[ad_admin_footer]
"
