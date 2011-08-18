set_the_usual_form_variables
# event_id, column_name, pretty_name

set db [ns_db gethandle]

set selection [ns_db 1row $db "select 
a.activity_id, a.short_name as activity_name, v.city,
v.usps_abbrev, v.iso, display_after, 
to_char(start_time, 'fmDay, fmMonth DD, YYYY') as compact_date
from events_events e, events_activities a, 
events_venues v
where e.event_id = $event_id
and e.activity_id = a.activity_id
and v.venue_id = e.venue_id
"]

set_variables_after_query
set pretty_location [events_pretty_location $db $city $usps_abbrev $iso]

ns_return 200 text/html "[ad_header "Delete Field From Event"]

<h2>Delete Column $column_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" Event] "Custom Field"]
<hr>

<form action=\"event-field-delete-2.tcl\" method=POST>
[export_form_vars event_id column_name]

Do you really want to remove this field from the event, $activity_name, occurring on $compact_date in $pretty_location?<p>
You may not be able to undo this action.
<center>
<input type=submit value=\"Yes, Remove This Field\">
</center>

[ad_footer]
"