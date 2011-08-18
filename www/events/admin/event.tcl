set_the_usual_form_variables
# event_id

ReturnHeaders

set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]


set selection [ns_db 1row $db "select 
a.activity_id, a.short_name, v.city,
v.usps_abbrev, v.iso, display_after, 
to_char(start_time, 'fmDay, fmMonth DD, YYYY') as compact_date, 
to_char(start_time, 'YYYY-MM-DD HH24:MI') as start_pretty_time, 
to_char(end_time, 'YYYY-MM-DD HH24:MI') as end_pretty_time,
to_char(reg_deadline, 'YYYY-MM-DD HH24:MI') as deadline_pretty_time,  
u.first_names || ' ' || u.last_name as creator_name,
e.available_p,
e.max_people,
e.refreshments_note, 
e.av_note,
e.additional_note,
decode(e.reg_cancellable_p,
       't', 'yes',
       'f', 'no',
       'no') as reg_cancellable_p,
decode (e.reg_needs_approval_p,
       't', 'yes',
       'f', 'no',
       'no') as reg_needs_approval_p
from events_events e, events_activities a, users u,
events_venues v
where e.event_id = $event_id
and e.activity_id = a.activity_id
and v.venue_id = e.venue_id
and u.user_id = e.creator_id
"]

set_variables_after_query
set pretty_location [events_pretty_location $db_sub $city $usps_abbrev $iso]

#release the handles for ad_header
ns_db releasehandle $db
ns_db releasehandle $db_sub

ns_write "[ad_header "$pretty_location: $compact_date"]"

set db [ns_db gethandle]

ns_write "
<h2>$pretty_location: $compact_date</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Event"]
<hr>

<ul>
"

set n_orders [database_to_tcl_string $db "select count(*) 
from events_reg_not_canceled e, events_prices p
where p.price_id = e.price_id
and p.event_id = $event_id
"]

set sql_post_select "from users, events_registrations r, events_prices p
where p.event_id = $event_id
and users.user_id = r.user_id
and p.price_id = r.price_id
"

if { $n_orders > 1 } {
    ns_write "<li><a href=\"order-history-one-event.tcl?event_id=$event_id\">View All $n_orders Orders for this Event</a>\n
"
} elseif { $n_orders == 1 } {
    ns_write "<li><a href=\"order-history-one-event.tcl?event_id=$event_id\">View the Single Order for this Event</a>\n
"
} else {
    ns_write "<li>There have been no orders for this event\n"
}

ns_write "<li><a href=\"/events/order-one.tcl?event_id=$event_id\">View the page that users see</a>
<li><a href=\"spam-selected-event.tcl?event_id=$event_id\">Spam this event</a>

</ul>


<table cellpadding=3>
<tr>
  <th valign=top>Creator</th>
  <td valign=top>$creator_name</td>
<tr>
  <th valign=top>Location</th>
  <td valign=top>$pretty_location</td>
</tr>
<tr>
  <th valign=top>Confirmation Message</th>
  <td valign=top>$display_after</td>
</tr>
<tr>
  <th valign=top>Start Time</th>
  <td valign=top>$start_pretty_time</td>
<tr>
  <th valign=top>End Time</th>
  <td valign=top>$end_pretty_time</td>
</tr>
<tr>
  <th valign=top>Registration Deadline</th>
  <td valign=top>$deadline_pretty_time</td>
</tr>
<tr>
 <th valign=top>Maximum Capacity
 <td valign=top>$max_people
<tr>
 <th valign=top>Registration Cancellable?
 <td valign=top>$reg_cancellable_p
<tr>
 <th valign=top>Registration Needs Approval?
 <td valign=top>$reg_needs_approval_p
<tr>
  <th valign=top>Availability Status</th>
"
if {[string compare $available_p "t"] == 0} {
    ns_write "<td valign=top>Current"
} else {
    ns_write "<td valign=top>Discontinued"
}

ns_write " &nbsp; (<a href=\"event-toggle-available-p.tcl?event_id=$event_id\">toggle</a>)
"
if {[string compare $available_p "f"] == 0 && $n_orders > 0} {
    ns_write "
    <br><font color=red>You may want to 
    <a href=\"spam/action-choose.tcl?[export_url_vars sql_post_select]\">spam the registrants for this event</a>
    to notify them the event is canceled.</font>"
}


ns_write "
</table>
<ul><li><a href=\"event-edit.tcl?[export_url_vars event_id]\">
     Edit Event Properties</a></ul>"

#ns_write "
#<h3>Pricing</h3>
#<ul>
#"

#set selection [ns_db select $db "select
#price_id, description as product_name,
#decode (price, 0, 'free', price) as pretty_price, 
#description, available_date,
#expire_date
#from events_prices
#where event_id = $event_id"]
#
#while {[ns_db getrow $db $selection]} {
#    set_variables_after_query
#
#    if {$pretty_price != "free"} {
#	set pretty_price  $[util_commify_number $pretty_price]
#    }
#
#    ns_write "<li>
#    <a href=\"event-price-ae.tcl?[export_url_vars event_id price_id]\">
#    $product_name</a>: $pretty_price
#    (available [util_AnsiDatetoPrettyDate $available_date] to
#    [util_AnsiDatetoPrettyDate $expire_date])"
#}
#
#ns_write "
#<br><br>
#<li><a href=\"event-price-ae.tcl?[export_url_vars event_id]\">
#Add a special price</a> 
#(student discount, late price, etc.)
#</ul>"

ns_write "
<h3>Custom Fields</h3>
You may define custom fields which you would like to
collect from registrants.
<p>
<table>
"

set number_of_fields [database_to_tcl_string $db "select count(*) from events_event_fields where event_id=$event_id"]

set selection [ns_db select $db "select 
column_name, pretty_name, column_type, column_actual_type,
column_extra, sort_key
from events_event_fields
where event_id = $event_id
order by sort_key
"]

set counter 0 
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter 

    if { $counter == $number_of_fields } {
	ns_write "<tr><td><ul><li>$column_name ($pretty_name), $column_actual_type ($column_type) $column_extra<td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"event-field-add.tcl?event_id=$event_id&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"event-field-delete.tcl?[export_url_vars event_type column_name event_id]\">delete</a>&nbsp;\]</font></ul>\n"
    } else {
	ns_write "<tr><td><ul><li>$column_name ($pretty_name), $column_actual_type ($column_type) $column_extra<td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"event-field-add.tcl?event_id=$event_id&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"event-field-swap.tcl?event_id=$event_id&sort_key=$sort_key\">swap&nbsp;with&nbsp;next</a>&nbsp;|&nbsp;<a href=\"event-field-delete.tcl?[export_url_vars event_id column_name]\">delete</a>&nbsp;\]</font></ul>\n"
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
<li><a href=\"event-field-add.tcl?[export_url_vars event_id]\">add a field</a>
</ul>
<h3>Organizers</h3>
<ul>
"

set selection [ns_db select $db "select 
u.first_names || ' ' || u.last_name as organizer_name,
u.user_id,
om.role
from events_organizers_map om, users u
where event_id=$event_id
and u.user_id = om.user_id
"]

set org_counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"organizer-edit.tcl?[export_url_vars user_id event_id]\">$organizer_name: $role</a>\n"
    incr org_counter
}

if {$org_counter == 0} {
    ns_write "<li>There are no organizers for this event"
}

set sql_post_select "from users, events_organizers_map m
where m.event_id = $event_id
and users.user_id = m.user_id"

ns_write "<br><br>
<li><a href=\"organizer-add.tcl?[export_url_vars event_id]\">Add another organizer</a>
"
if {$org_counter > 0} {
    ns_write "<li><a href=\"spam/action-choose.tcl?[export_url_vars sql_post_select]\">Spam all the organizers for this event</a>"
}

ns_write "</ul>"

set return_url "/events/admin/event.tcl?event_id=$event_id"
set on_which_table "events_events"
set on_what_id "$event_id"

ns_write "
<h3>Agenda Files</h3>
<ul>
"

set selection [ns_db select $db "select 
file_title, file_id 
from events_file_storage
where on_which_table = '$on_which_table'
and on_what_id = '$on_what_id'"]

set agenda_count 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li>
    <a href=\"attach-file/download.tcl?[export_url_vars file_id]\">
    $file_title</a> |
    <a href=\"attach-file/file-remove.tcl?[export_url_vars file_id return_url]\">
    Remove this file\n
    "
    incr agenda_count
}

if {$agenda_count == 0} {
    ns_write "<li>There are no agenda files for this event"
}

ns_write "<br><br>
<li><a href=\"attach-file/upload.tcl?[export_url_vars return_url on_which_table on_what_id]\">Upload an agenda file</a>
</ul>
"

set group_link [ad_urlencode [database_to_tcl_string $db "select
ug.short_name from user_groups ug, events_events e
where ug.group_id = e.group_id
and e.event_id = $event_id"]]

ns_write "<h3>Event User Group</h3>
You may manage the user group for this event.
<ul>
<li><a href=\"/groups/admin/$group_link/\">Manage this event's user
group</a>
</ul>
"

#set selection [ns_db select $db "select 1 from
#events_calendar_seeds
#where activity_id = $activity_id"]

#if {![empty_string_p $selection]} {
#    ns_write "<h3>Event Calendars</h3>
#    This event's activity has a default calendar.  You may populate
#    this event's calendar or the site calendar based upon this default
#    activity calendar.
#    <p>
#    <ul>
#    <li><a href=\"calendars/index.tcl?[export_url_vars event_id]\">Manage event calendars</a>
#    </ul>
#    "
#}

ns_write "
<h3>Event Notes</h3>
<table>
<tr>
  <th valign=top>Refreshments Note</th>
  <td><form method=POST action=\"event-update-refreshments-note.tcl\">
      [export_form_vars event_id]
      <textarea name=refreshments_note rows=6 cols=65 wrap=soft>$refreshments_note</textarea>
      <br>
      <input type=submit value=\"Update\">
      </form>
</tr>
<tr>
  <th valign=top>Audio/Visual Note</th>
  <td><form method=POST action=\"event-update-av-note.tcl\">
      [export_form_vars event_id]
      <textarea name=av_note rows=6 cols=65 wrap=soft>$av_note</textarea>
      <br>
      <input type=submit value=\"Update\">
      </form>
</tr>
<tr>
  <th valign=top>Additional Note</th>
  <td><form method=POST action=\"event-update-additional-note.tcl\">
      [export_form_vars event_id]
      <textarea name=additional_note rows=6 cols=65 wrap=soft>$additional_note</textarea>
      <br>
      <input type=submit value=\"Update\">
      </form>
</tr>
</table>
[ad_footer]"



