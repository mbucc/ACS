set db [ns_db gethandle]

set_the_usual_form_variables
#event_id, user_id, role, responsibilities, bio

ns_db dml $db "begin transaction"
ns_db dml $db "update events_organizers_map
set role='$QQrole',
responsibilities='$QQresponsibilities'
where event_id = $event_id
and user_id = $user_id"
ns_db dml $db "update users 
set bio='$QQbio'
where user_id = $user_id"
ns_db dml $db "end transaction"

ad_returnredirect "event.tcl?[export_url_vars event_id]"
