# $Id: action-role-map.tcl,v 3.0.4.1 2000/04/28 15:09:25 carsten Exp $
set_the_usual_form_variables

# group_id, role, action


set db [ns_db gethandle]

# insert the row if it was not there
ns_db dml $db "insert into user_group_action_role_map (group_id, role, action, creation_user, creation_ip_address) select $group_id, '$QQrole', '$QQaction', [ad_get_user_id], '[DoubleApos [ns_conn peeraddr]]' from dual where not exists (select role from user_group_action_role_map where group_id = $group_id and role = '$QQrole' and action = '$QQaction')"


ad_returnredirect "group.tcl?group_id=$group_id"

