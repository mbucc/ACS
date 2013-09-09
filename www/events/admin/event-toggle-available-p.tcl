# File:  events/admin/event-toggle-available-p.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  toggles the availability of an event.
#####

ad_page_contract {
    Toggles the availability of an event.

    @param event_id the event whose availability we're toggling

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-toggle-available-p.tcl,v 3.4.6.3 2000/07/21 03:59:37 ron Exp
} {
    {event_id:integer,notnull}
}


db_dml unused "update events_events 
               set available_p = logical_negation(available_p) 
               where event_id = :event_id"

db_release_unused_handles
ad_returnredirect "event.tcl?event_id=$event_id"
##### EOF
