# File:  events/admin/event-add.tcl
# Owner: bryanche@arsdigita.com
# Purpose: Allow an admin to select a venue for a new event, or
#      add a new venue if necessary first.
#####

ad_page_contract {
    Purpose: Allow an admin to select a venue for a new event, or
    add a new venue if necessary first.

    @param activity_id the activity to which we're adding an event

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-add.tcl,v 3.7.6.4 2000/09/22 01:37:36 kevin Exp
} {
    {activity_id:integer,notnull}
}


set return_url "/events/admin/event-add-2.tcl?activity_id=$activity_id"
set whole_page ""



set activity_name [db_string a_name "select short_name as activity_name 
               from events_activities where activity_id = $activity_id"]
set venues_widget [events_venues_widget]

append whole_page "[ad_header "Add a New Event"]"

append whole_page "
<h2>Add a New Event</h2> for $activity_name
<br>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Add Event"]
<hr>

<form action=\"event-add-2\" method=get>
[export_form_vars activity_id]
<p>
<h3>Choose a Venue</h3>
<p>
<form method=post action=\"event-add-2\">
<table>
<tr>
 <td valign=top>Select a venue for your new event: 
 <td valign=top>$venues_widget"

if {![empty_string_p $venues_widget]} {
    append whole_page "
    <tr><td><br>
    <tr><td>
        <td><center> <input type=submit value=\"Continue\"> </center>
    "
} else {
    append whole_page "<tr><td><br><ul><li>There are no venues in the system</ul>"
}

append whole_page "
</table>
<p>
If you do not see your venue above, you may 
<a href=\"venues-ae?[export_url_vars return_url]\">add a new venue</a>.
"

## clean up.
append whole_page "</table></blockquote> [ad_footer]"


doc_return  200 text/html $whole_page
##### File Over
