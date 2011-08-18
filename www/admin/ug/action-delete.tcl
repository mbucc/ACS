# $Id: action-delete.tcl,v 3.0.4.1 2000/04/28 15:09:24 carsten Exp $
set_the_usual_form_variables

# group_id, action

set db [ns_db gethandle]

ns_db dml $db "delete from user_group_actions
where group_id = $group_id
and action = '$QQaction'"

ad_returnredirect "group.tcl?group_id=$group_id"

