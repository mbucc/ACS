# File: events/admin/event-field-delete.tcl
# Owner: bryanche@arsdigita.com
# Purpose: Asks the user to verify a deletion request (generally made
#          by following a 'delete' link next to the field on the 
#          admin/event.tcl page.
#####
ad_page_contract {
    Asks the user to verify a deletion request (generally made
    by following a 'delete' link next to the field on the 
    admin/event.tcl page.

    @param event_id the event whose field we are deleting
    @param column_name the column of the field we are deleting

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-field-delete.tcl,v 3.5.6.4 2000/09/22 01:37:37 kevin Exp
} {
    {event_id:integer,notnull}
    {column_name}
}

db_1row event_info "select 
	a.activity_id, a.short_name as activity_name, v.city,
	v.usps_abbrev, 
        decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location,
	to_char(start_time, 'fmDay, fmMonth DD, YYYY') as compact_date
   from events_events e, events_activities a, events_venues v,
        country_codes cc
  where  e.event_id = $event_id
    and  e.activity_id = a.activity_id
    and  v.venue_id = e.venue_id
    and  cc.iso = v.iso
"

set pretty_location "$city, $big_location"



doc_return  200 text/html " 
   [ad_header "Delete Field From Event"]
 <h2>Delete Column $column_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" Event] "Custom Field"]
<hr>

<form action=\"event-field-delete-2\" method=POST>
[export_form_vars event_id column_name]

Do you really want to remove this field from the event, $activity_name, occurring on $compact_date in $pretty_location?<p>
You may not be able to undo this action.

<center> <input type=submit value=\"Yes, Remove This Field\"> </center>

[ad_footer]
"

##### File Over
