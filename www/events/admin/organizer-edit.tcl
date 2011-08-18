set db [ns_db gethandle]

set_the_usual_form_variables
#event_id, user_id

set selection [ns_db 1row $db "select 
m.role, m.responsibilities,
u.bio, u.first_names || ' ' || u.last_name as org_name,
u.email,
a.short_name,
a.activity_id,
v.city, v.usps_abbrev, v.iso,
to_char(e.start_time, 'fmDay, fmMonth DD, YYYY') as compact_date
from events_organizers_map m, events_events e, users u, events_activities a,
events_venues v
where m.event_id = $event_id
and m.user_id = $user_id
and e.event_id = m.event_id
and v.venue_id = e.venue_id
and a.activity_id = e.activity_id
and u.user_id = m.user_id"]
set_variables_after_query

ReturnHeaders
ns_write "[ad_header "Edit Organizer for $short_name"]

<h2>Edit Organizer for $short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" "Event"] "Organizer"]

<hr>

<h3>Organizer Description</h3>

<form method=post action=organizer-edit-2.tcl>
[export_form_vars event_id user_id]

<table>
<tr>
 <th align=left>Organizer:
 <td>$org_name ($email)
<tr>
 <th align=left>Event name:
 <td>$short_name
<tr>
 <th align=left>Event location:
 <td>[events_pretty_location $db $city $usps_abbrev $iso]
<tr>
 <th align=left>Event date:
 <td>$compact_date
<tr>
 <th align=left>Role:
 <td><input name=role type=text size=20 value=\"$role\">
<tr>
 <th align=left>Responsibilities:
 <td><textarea name=responsibilities rows=10 cols=70 wrap=soft>$responsibilities</textarea>
<tr>
 <th align=left>Biography:
 <td><textarea name=bio rows=10 cols=70 wrap=soft>$bio</textarea>
</table>
</form>
<p>
<center>
<input type=submit value=\"Update Organizer\">
</center>
<hr>
You may also remove this organizer from this event:
<form method=post action=organizer-delete.tcl>
[export_form_vars event_id user_id]

<center>
<input type=submit value=\"Remove Organizer\">
</form>
[ad_footer]"


