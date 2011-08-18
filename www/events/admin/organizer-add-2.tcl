set_the_usual_form_variables
#user_id_from_search, first_names_from_search, last_name_from_search, email_from_search, event_id

set db [ns_db gethandle]

# check if this guy is already a organizer
set selection [ns_db 0or1row $db "select 1 from
events_organizers_map
where user_id = $user_id_from_search
and event_id = $event_id
"]
if {![empty_string_p $selection]} {
    set org_name [database_to_tcl_string $db "select 
    first_names || ' ' || last_name
    from users
    where user_id=$user_id_from_search"]
    ad_return_error "Organizer Already Exists" "You have already 
    given $org_name an organizing role for this event.  You may
    <ul>
     <li><a href=\"organizer-edit.tcl?user_id=$user_id_from_search&event_id=$event_id\">view/edit
     this organizer's responsibilities</a>
     <li><a href=\"index.tcl\">return to administration</a>
    </ul>"
    return
}

set bio [database_to_tcl_string $db "select bio from users 
where user_id = $user_id_from_search"]

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

<form method=post action=organizer-add-3.tcl>
[export_form_vars event_id]
<input type=hidden name=user_id value=\"$user_id_from_search\">
You have selected $first_names_from_search
$last_name_from_search ($email_from_search) to be your organizer for the
$event_name event.
Please provide the following information:
<p>
<table>
<tr>
 <th align=left>Role
 <td><input type=text name= role size=20>
<tr>
 <th align=left>Responsibilities
 <td><textarea name=responsibilities rows=10 cols=70></textarea>
<tr>
 <th align=left>Biography
 <td><textarea name=bio rows=10 cols=70>$bio</textarea>
</table>
<p>
<center>
<input type=submit value=\"Add Organizer\">
</center>
</form>
[ad_footer]
"




