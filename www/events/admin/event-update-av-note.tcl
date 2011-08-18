set_the_usual_form_variables

# event_id, av_note

set db [ns_db gethandle]

ns_db dml $db "update events_events 
set av_note = '$QQav_note'
where event_id = $event_id"

ad_returnredirect "event.tcl?event_id=$event_id"
