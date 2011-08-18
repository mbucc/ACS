# $Id: administrator-delete.tcl,v 3.0.4.1 2000/04/28 15:08:24 carsten Exp $
set_the_usual_form_variables

# topic, topic_id, admin_group_id, user_id

set db [ns_db gethandle]

ns_db dml $db "delete from user_group_map
where user_id = $user_id
and group_id = $admin_group_id"

ad_returnredirect "topic-administrators.tcl?[export_url_vars topic topic_id]"

