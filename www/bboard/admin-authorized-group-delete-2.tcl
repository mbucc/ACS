# $Id: admin-authorized-group-delete-2.tcl,v 3.0.4.1 2000/04/28 15:09:40 carsten Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic, group_id

set db [ns_db gethandle]
 
if  {[bboard_get_topic_info] == -1} {
    return}

# cookie checks out; user is authorized

ns_db dml $db "delete from bboard_workgroup
where group_id = $group_id and
topic='$QQtopic'"

ad_returnredirect "admin-authorized-users.tcl?topic=[ns_urlencode $topic]"
