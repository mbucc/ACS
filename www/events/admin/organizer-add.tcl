set db [ns_db gethandle]

set_the_usual_form_variables
#event_id

set selection [ns_db 1row $db "select a.short_name as event_name,
a.activity_id
from events_activities a, events_events e
where e.event_id = $event_id
and a.activity_id = e.activity_id"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_header "Add a New Organizer"]
<h2>Add a New Organizer</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" "Event"] "Add Organizer"]
<hr>

<form action=\"/user-search.tcl\" method=get>
<input type=hidden name=target value=\"/events/admin/organizer-add-2.tcl\">
<input type=hidden name=custom_title value=\"Choose a Member to Add as a Organizer for the $event_name event\">
<input type=hidden name=event_id value=$event_id>
<input type=hidden name=passthrough value=event_id>

<P>
<h3>Identify Organizer</h3>
<p>
Search for a user to be the organizer of the $event_name event by:<br>
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<p>
<center>
<input type=submit value=\"Search for a organizer\">
</center>
</form>
<p>
[ad_footer]
"

