# $Id: admin-authorized-group-delete.tcl,v 3.0 2000/02/06 03:32:22 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, group_id

set db [ns_db gethandle]
 

if  {[bboard_get_topic_info] == -1} {
    return}

# cookie checks out; user is authorized


set selection [ns_db 1row $db "select group_name from
user_groups 
where group_id = $group_id"]

set_variables_after_query


ReturnHeaders

ns_write "[ad_admin_header "Really remove $group_name"]
<h2>Really remove $group_name </h2>
from <a href=\"admin-authorized-users.tcl?topic=[ns_urlencode $topic]\">$topic user list?</a>
<hr><p>

<form action=admin-authorized-group-delete-2.tcl method=get>
<input type=hidden name=group_id value=\"$group_id\">
<input type=hidden name=topic value=\"$topic\">
<input type=submit name=submit value=\"Delete Group\">
</form>

<form action=admin-authorized-users.tcl method=get>
<input type=hidden name=group_id value=\"$group_id\">
<input type=hidden name=topic value=\"$topic\">
<input type=submit name=submit value=\"Cancel\">
</form>

[bboard_footer]"

