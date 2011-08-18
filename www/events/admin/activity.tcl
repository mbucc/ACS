set_the_usual_form_variables
#activity_id

set db [ns_db gethandle]

ReturnHeaders

#activities.default_price,
set selection [ns_db 1row $db "select activities.short_name, 
activities.creator_id, 
activities.description, 
activities.detail_url,
activities.available_p,
u.user_id,
u.first_names || ' ' || u.last_name as creator
from events_activities activities, users u
where activity_id = $activity_id
and u.user_id = activities.creator_id"]

set_variables_after_query

#release the handles here for ad_header, then get them again
ns_db releasehandle $db
#ns_db releasehandle $db_sub

ns_write "[ad_header $short_name]

<h2>$short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] "Activity"]
<hr>

<h3>Events for this Activity</h3>
"

#get the handles again
set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]


set selection [ns_db select $db "select e.event_id, v.city,
v.usps_abbrev, v.iso, e.start_time, count(reg_id) as n_orders from
events_events e, events_reg_not_canceled r, events_venues v,
events_prices p where e.activity_id = $activity_id and p.price_id =
r.price_id(+) and e.event_id = p.event_id(+) and v.venue_id =
e.venue_id group by e.event_id, v.city, v.usps_abbrev, v.iso,
e.start_time order by start_time"]

ns_write "<ul>\n"

set count 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr count
    ns_write "<li><a href=\"event.tcl?event_id=$event_id\">[events_pretty_location $db_sub $city $usps_abbrev $iso]</a> [util_AnsiDatetoPrettyDate $start_time]\n (registration: $n_orders)"
}
if { $count == 0 } {
    ns_write "No events for this activity have been created.\n"
}

if {$available_p == "t"} {
    ns_write "<p>
    <a href=\"event-add.tcl?activity_id=$activity_id\">Add an Event</a>
    "
} 

ns_write "
</ul>
<h3>Activity Description</h3>
<table>
<tr>
  <th valign=top>Name</th>
  <td valign=top>$short_name</td>
</tr>
<tr>
  <th valign=top>Creator</th>
  <td valign=top>$creator</td>
</tr>
"

#<tr>
# <th valign=top>Default Price
# <td valign=top>$[util_commify_number $default_price]

ns_write "
<tr>
 <th valign=top>URL
 <td valign=top>$detail_url
<tr>
  <th valign=top>Description</th>
  <td valign=top>$description</td>
</tr>
<tr>
  <th valign=top>Current or Discontinued</th>
"
if {[string compare $available_p "t"] == 0} {
    ns_write "<td valign=top>Current</td>"
} else {
    ns_write "<td valign=top>Discontinued</td>"
}

ns_write "
</table>

<p>
<ul>
<li><a href=\"activity-edit.tcl?[export_url_vars activity_id]\">Edit Activity</a>
</ul>
"

ns_write "
<h3>Activity Custom Fields</h3>
You may define default custom fields which you would like to
collect from registrants for this activity type.
<p>
<table>
"

set number_of_fields [database_to_tcl_string $db "select count(*) from events_activity_fields where activity_id=$activity_id"]

set selection [ns_db select $db "select 
column_name, pretty_name, column_type, column_actual_type,
column_extra, sort_key
from events_activity_fields
where activity_id = $activity_id
order by sort_key
"]

set counter 0 
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter 

    if { $counter == $number_of_fields } {
	ns_write "<tr><td><ul><li>$column_name ($pretty_name), $column_actual_type ($column_type) $column_extra<td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"activity-field-add.tcl?activity_id=$activity_id&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"activity-field-delete.tcl?[export_url_vars activity_type column_name activity_id]\">delete</a>&nbsp;\]</font></ul>\n"
    } else {
	ns_write "<tr><td><ul><li>$column_name ($pretty_name), $column_actual_type ($column_type) $column_extra<td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"activity-field-add.tcl?activity_id=$activity_id&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"activity-field-swap.tcl?activity_id=$activity_id&sort_key=$sort_key\">swap&nbsp;with&nbsp;next</a>&nbsp;|&nbsp;<a href=\"activity-field-delete.tcl?[export_url_vars activity_id column_name]\">delete</a>&nbsp;\]</font></ul>\n"
    }
}

if { $counter == 0 } {
    ns_write "
    <tr><td><ul><li>no custom fields currently collected</ul>
    "
}

ns_write "
</table>
<p>
<ul>
<li><a href=\"activity-field-add.tcl?[export_url_vars activity_id]\">add a field</a>
</ul>
"

ns_write "
<h3>Accounting</h3>
<ul>
<li><a href=\"order-history-one-activity.tcl?activity_id=$activity_id\">View All Orders for this Activity</a>

</ul>

[ad_footer]"
