set_the_usual_form_variables

# event_id

set db [ns_db gethandle]

ns_db dml $db "update events_events 
set available_p = logical_negation(available_p) where event_id = $event_id"

ad_returnredirect "event.tcl?event_id=$event_id"
