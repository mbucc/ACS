set db [ns_db gethandle]

set_the_usual_form_variables
#event_id, user_id

set selection [ns_db 1row $db "select 
u.first_names || ' ' || u.last_name as org_name,
m.role,
a.short_name,
a.activity_id
from users u, events_events e, events_activities a, events_organizers_map m
where m.event_id = $event_id
and m.user_id = $user_id
and e.event_id = m.event_id
and a.activity_id = e.activity_id
and u.user_id = m.user_id"]
set_variables_after_query

ReturnHeaders
ns_write "[ad_header "Remove Organizer from $short_name"]

<h2>Remove $org_name from $short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" "Event"] "Edit Event"]
<hr>

<h3>Remove Organizer</h3>

<form method=post action=organizer-delete-2.tcl>
[export_form_vars event_id user_id]
Are you sure you want to remove $org_name from being $role for $short_name?
<p>
<center>
<input type=submit value=\"Remove $org_name\">
</center>
</form>
[ad_footer]"