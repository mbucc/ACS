set_the_usual_form_variables

# event_id, after (optional)

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

ReturnHeaders 

ns_write "[ad_header "Add a field to $activity_name"]

<h2>Add a field</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" Event] "Custom Field"]
<hr>
<p>
Add a field to the event, $activity_name, occurring on $compact_date in $pretty_location.
<p>
<form action=\"event-field-add-2.tcl\" method=POST>
[export_form_vars event_id after]

Column Actual Name:  <input name=column_name type=text size=30>
<br>
<i>no spaces or special characters except underscore</i>

<p>

Column Pretty Name:  <input name=pretty_name type=text size=30>

<p>


Column Type:  [ad_user_group_column_type_widget]
<p>

Column Actual Type:  <input name=column_actual_type type=text size=30>
(used to feed Oracle, e.g., <code>char(1)</code> instead of boolean)


<p>

If you're a database wizard, you might want to add some 
extra SQL, such as \"not null\"<br>
Extra SQL: <input type=text size=30 name=column_extra>

<p>

(note that you can only truly add not null columns when the table is
empty, i.e., before anyone has entered the contest)

<p>

<input type=submit value=\"Add this new column\">

</form>

[ad_footer]
"
