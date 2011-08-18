set db [ns_db gethandle]

set_the_usual_form_variables
#user_id, event_id

ns_db dml $db "delete from events_organizers_map
where event_id = $event_id
and user_id = $user_id"

ad_returnredirect "event.tcl?[export_url_vars event_id]"
