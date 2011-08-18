# $Id: admin-authorize-user-new-2.tcl,v 3.0.4.1 2000/04/28 15:09:40 carsten Exp $
set_the_usual_form_variables

# user_id_from_search, topic

set db [ns_db gethandle]

ns_db dml $db "insert into bboard_workgroup (user_id,topic)
 select $user_id_from_search, '$QQtopic' from DUAL where
0 = (select count(*)  from bboard_workgroup
where user_id=$user_id_from_search and topic='$QQtopic')"

ad_returnredirect "admin-authorized-users.tcl?topic=[ns_urlencode $topic]"
