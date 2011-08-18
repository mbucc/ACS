# $Id: admin-authorized-users.tcl,v 3.0 2000/02/06 03:32:26 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}
 
if  {[bboard_get_topic_info] == -1} {
    return}

# cookie checks out; user is authorized

ReturnHeaders

ns_write "[ad_admin_header "Authorized users of $topic"]
<h2>Authorizated users </h2>
of <a href=\"admin-home.tcl?topic=[ns_urlencode $topic]\">$topic</a>
<hr><p>


<p>
<h4>Users</h4>
"

set selection [ns_db select $db  "select bboard_workgroup.user_id, last_name, first_names 
from bboard_workgroup, users
where bboard_workgroup.user_id = users.user_id
and topic = '$QQtopic'
ORDER BY last_name"]

ns_write "<table>"

while {[ns_db getrow $db $selection]}   {
    set_variables_after_query
    ns_write "<tr><td><a href=\"/shared/community-member.tcl?user_id=$user_id\">$last_name, $first_names</a> </td><td> <A HREF=\"admin-authorized-user-delete.tcl?[export_url_vars user_id topic]\">Remove</a></td></tr>"
}

ns_write "
</table> 
<p>
<A href=\"admin-authorize-user-new.tcl?topic=[ns_urlencode $topic]\">Add a new user</a><h4>Groups</h4>"

set selection [ns_db select $db  "select bboard_workgroup.group_id, group_name
from bboard_workgroup, user_groups
where bboard_workgroup.group_id = user_groups.group_id
and topic = '$QQtopic'
ORDER BY lower(group_name)"]

ns_write "<table>"

while {[ns_db getrow $db $selection]}   {
    set_variables_after_query
    ns_write "<tr><td>$group_name</td><td> <A HREF=\"admin-authorized-group-delete.tcl?[export_url_vars group_id topic]\">Remove</a></td></tr>"
}

ns_write "</table>
<p>

<A href=\"admin-authorize-group-new.tcl?topic=[ns_urlencode $topic]\">Add a new group</a>


[bboard_footer]"
