# $Id: admin-authorize-group-new-2.tcl,v 3.0.4.1 2000/04/28 15:09:40 carsten Exp $
set_the_usual_form_variables

# group_id, topic

set db [ns_db gethandle]

ns_db dml $db "insert into bboard_workgroup (group_id,topic)
 select $group_id, '$QQtopic' from DUAL where
0 = (select count(*)  from bboard_workgroup
where group_id = $group_id and topic='$QQtopic')"

ad_returnredirect "admin-authorized-users.tcl?topic=[ns_urlencode $topic]"
