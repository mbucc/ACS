# $Id: role-delete.tcl,v 3.0.4.1 2000/04/28 15:09:34 carsten Exp $
set_the_usual_form_variables

# group_id, role

set db [ns_db gethandle]


ns_db dml $db "delete from user_group_roles
where group_id = $group_id
and role = '$QQrole'"

ad_returnredirect "group.tcl?group_id=$group_id"

