# $Id: membership-refuse-2.tcl,v 3.0.4.1 2000/04/28 15:09:33 carsten Exp $
set_the_usual_form_variables

# group_id, user_id

set db [ns_db gethandle]

ns_db dml $db "delete from user_group_map_queue where
user_id = $user_id and group_id = $group_id"

ad_returnredirect "group.tcl?[export_url_vars group_id]"