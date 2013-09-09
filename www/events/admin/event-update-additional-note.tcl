# File:  events/admin/event-update-additional-note.tcl
# Owner: bryanche@arsdigita.com
# Purpose: updates additional_note.
#####

ad_page_contract {
    updates additional_note

    @param event_id the event whose note we are updating
    @param additional_note the note we are updating

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-update-additional-note.tcl,v 3.6.2.5 2000/07/21 03:59:37 ron Exp
} {
    {event_id:integer,notnull}
    {additional_note:html,trim}
}

db_dml update_event "update events_events 
set additional_note = empty_clob()
where event_id = $event_id
returning additional_note into :1
" -clobs [list $additional_note]

db_release_unused_handles

ad_returnredirect "event.tcl?event_id=$event_id"
##### EOF
