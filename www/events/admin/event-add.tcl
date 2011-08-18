set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]


set_form_variables
# activity_id

ReturnHeaders

set selection [ns_db 1row $db "select short_name as activity_name from events_activities where activity_id = $activity_id"]
set_variables_after_query

set return_url "/events/admin/event-add-2.tcl?activity_id=$activity_id"

set venues_widget [events_venues_widget $db $db_sub]

#release the db handle for ad_header
ns_db releasehandle $db
ns_db releasehandle $db_sub
ns_write "[ad_header "Add a New Event"]"

#get the handles again
set db [ns_db gethandle]

ns_write "
<h2>Add a New Event</h2>
for $activity_name<br>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Add Event"]
<hr>
<form action=\"event-add-2.tcl\" method=get>
[export_form_vars activity_id]
<P>
<h3>Choose a Venue</h3>
<p>
<form method=post action=\"event-add-2.tcl\">
<table>
<tr>
 <td valign=top>Select a venue for your new event: 
 <td valign=top>$venues_widget"

if {![empty_string_p $venues_widget]} {
    ns_write "
    <tr>
    <td><br>
    <tr>
    <td>
    <td><center>
    <input type=submit value=\"Continue\">
    </center>
    "
} else {
    ns_write "<tr><td><br><ul><li>There are no venues in the system</ul>"
}

ns_write "
</table>
<p>
If you do not see your venue above, you may 
<a href=\"venues-ae.tcl?[export_url_vars return_url]\">add a new venue</a>.


[ad_footer]
"

