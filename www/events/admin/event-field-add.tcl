# File: events/admin/event-field-add.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  This page allows a user to select a field to be associated
#           with the current activity.  'Column Type', like 'Column Pretty
#           Name', is for UI purposes.
#####

ad_page_contract {

    This page allows a user to select a field to be associated
    with the current activity.  'Column Type', like 'Column Pretty
    Name', is for UI purposes.

    @param event_id the event to which we are adding a field
    @param after field after which this new field will appear

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-field-add.tcl,v 3.5.6.4 2000/09/22 01:37:36 kevin Exp
} {
    {event_id:integer}
    {after:optional}
}


db_1row event_info "select 
	a.activity_id, a.short_name as activity_name, v.city,
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
[ad_header "Add a field to $activity_name"]
<h2>Add a field</h2>

[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" Event] "Custom Field"]
<hr>

<p>
Add a field to the event, $activity_name, occurring on $compact_date in $pretty_location.
<p>
<form action=\"event-field-add-2\" method=POST>
[export_form_vars event_id after]

Column Actual Name:  <input name=column_name type=text size=30> <br>
<b>this should not include any spaces or special characters except underscore</b>

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

##### File Over
