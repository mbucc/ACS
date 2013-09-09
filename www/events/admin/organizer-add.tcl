# File:  events/admin/organizer-add.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Choose a user to add as an organizer for an event.
#####

ad_page_contract {
    Choose a user to add as an organizer for an event.

    @param event_id the event to which to add the organizer
    @param role_id the role for which we're adding an organizer, if it has already been created

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id organizer-add.tcl,v 3.7.2.4 2000/09/22 01:37:38 kevin Exp
} {
    {event_id:integer,notnull}
    {role_id:integer,optional}
}


db_1row event_info "select a.short_name as event_name,
a.activity_id
from events_activities a, events_events e
where e.event_id = $event_id
and a.activity_id = e.activity_id"



doc_return  200 text/html "[ad_header "Add a New Organizer"]
<h2>Add a New Organizer</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" "Event"] "Add Organizer"]
<hr>

<form action=\"/user-search\" method=get>
<input type=hidden name=target value=\"/events/admin/organizer-add-2.tcl\">
<input type=hidden name=custom_title value=\"Choose a Member to Add as a Organizer for the $event_name event\">
[export_form_vars event_id role_id]
<input type=hidden name=passthrough value=\"event_id role_id\">

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
<input type=submit value=\"Search for an organizer\">
</center>
</form>
<p>
[ad_footer]
"
##### EOF
