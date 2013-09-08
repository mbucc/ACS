# File:  events/admin/event-update-refreshments-note.tcl
# Owner: bryanche@arsdigita.com
# Purpose: Updates the refreshments note for an event.
#####

ad_page_contract {
    updates refreshment_note

    @param event_id the event whose note we are updating
    @param refreshments_note the note we are updating

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-update-refreshments-note.tcl,v 3.6.2.4 2000/07/21 03:59:37 ron Exp
} {
    {event_id:integer,notnull}
    {refreshments_note:trim}
}


db_dml  update_note "update events_events 
set refreshments_note = empty_clob()
where event_id = $event_id
returning refreshments_note into :1
" -clobs [list $refreshments_note]

db_release_unused_handles
ad_returnredirect "event.tcl?event_id=$event_id"
##### EOF
