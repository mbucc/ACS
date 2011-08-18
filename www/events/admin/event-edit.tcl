#being called with the event_id, so know what row is going to be edited.
#want all the pieces of the form filled in, so you can then change the ones 
#you want 

set db [ns_db gethandle]

set_the_usual_form_variables
# event_id, maybe venue_id

set selection [ns_db 0or1row $db "select 
a.short_name,
a.activity_id,
v.venue_id,
e.display_after, e.start_time, e.max_people,
to_char(e.start_time,'YYYY-MM-DD HH24:MI:SS') as start_timestamp, 
to_char(e.end_time,'YYYY-MM-DD HH24:MI:SS') as end_timestamp,
to_char(e.reg_deadline,'YYYY-MM-DD HH24:MI:SS') as deadline_timestamp,
reg_cancellable_p, reg_needs_approval_p
from events_events e, events_venues v, events_activities a
where e.event_id= $event_id
and v.venue_id = e.venue_id
and a.activity_id = e.activity_id
"]

set_variables_after_query

#call this again to override venue_id
set_the_usual_form_variables
# event_id, maybe venue_id


set time_elements "<tr>
  <th align=right>Start:
  <td>[_ns_dateentrywidget start_time] [_ns_timeentrywidget start_time]
<tr>
  <th align=right>End:
  <td>[_ns_dateentrywidget end_time][_ns_timeentrywidget end_time]
<tr>
  <th align=right>Registration Deadline:
  <td>[_ns_dateentrywidget reg_deadline][_ns_timeentrywidget reg_deadline]
"

set stuffed_with_start [ns_dbformvalueput $time_elements "start_time" "timestamp" $start_timestamp]
set stuffed_with_se [ns_dbformvalueput $stuffed_with_start "end_time" "timestamp" $end_timestamp]
set stuffed_with_all_times [ns_dbformvalueput $stuffed_with_se "reg_deadline" "timestamp" $deadline_timestamp]

#set up html stuff
ReturnHeaders

set return_url "event-edit.tcl?event_id=$event_id"

#release the handle for ad_header
ns_db releasehandle $db
ns_write "
[ad_header "Edit Event"]"

set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]


ns_write "
<h2>Edit Event</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" "Event"] "Edit Event"]
<hr>
$short_name on [util_AnsiDatetoPrettyDate $start_time]
<form method=POST action=event-edit-2.tcl?event_id=$event_id>
[export_form_vars event_id]
<table>
<tr>
  <th align=right>Venue:
  <td>[events_venues_widget $db $db_sub $venue_id]
  <td align=left><a href=\"venues-ae.tcl?[export_url_vars return_url]\">Add a New Venue</a>
<tr>
 <th align=right>Maximum Capacity:
 <td><input type=text size=20 name=max_people value=$max_people>
<tr>
 <th align=right>Registration Cancellable?
 <td><select name=reg_cancellable_p>
"
if {$reg_cancellable_p == "t"} {
    ns_write "
    <option SELECTED value=\"t\">yes
    <option value=\"f\">no"
} else {
    ns_write "
    <option value=\"t\">yes
    <option SELECTED value=\"f\">no"
}

ns_write "
    </select>
 (Can someone cancel his registration?)
<tr>
 <th align=right>Registration Needs Approval?
 <td><select name=reg_needs_approval_p>
"

if {$reg_needs_approval_p == "t"} {
    ns_write "
     <option SELECTED value=\"t\">yes
     <option value=\"f\">no"
} else {
    ns_write "
     <option value=\"t\">yes
     <option SELECTED value=\"f\">no"
}
ns_write "
     </select>
 (Does a registration need to be approved?)
<tr>
  <th>Confirmation Message
  <td colspan=2><textarea name=display_after rows=8 cols=70 wrap=soft>$display_after</textarea>
$stuffed_with_all_times

</table>
<p>
<center>
<input type=submit value=\"Update\">
</center>
</form>
[ad_footer]"

