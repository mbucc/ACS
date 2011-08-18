set db [ns_db gethandle]

set_the_usual_form_variables
# activity_id, venue_id

ReturnHeaders

set new_event_id [database_to_tcl_string $db "select events_event_id_sequence.nextval from dual"]

#set new_product_id [database_to_tcl_string $db "select ec_product_id_sequence.nextval from dual"]

set new_price_id [database_to_tcl_string $db "select events_price_id_sequence.nextval from dual"]

set selection [ns_db 1row $db "select short_name as activity_name,
default_price 
from events_activities where activity_id = $activity_id"]
set_variables_after_query

set selection [ns_db 1row $db "select city, usps_abbrev, iso, max_people
from events_venues where venue_id=$venue_id"]
set_variables_after_query

ns_write "[ad_header "Add a New Event"]
<h2>Add a New Event for $activity_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Add Event"]

<hr>

<form method=get action=event-add-3.tcl>
[export_form_vars activity_id venue_id]
[philg_hidden_input event_id $new_event_id]

[philg_hidden_input price_id $new_price_id]

<table>
<tr>
 <td align=right>Location:
 <td>[events_pretty_location $db $city $usps_abbrev $iso]
<tr>
  <td align=right>Start Time:
  <td>[_ns_dateentrywidget start_time] [_ns_timeentrywidget start_time]
<tr>
  <td align=right>End Time:
  <td>[_ns_dateentrywidget end_time][_ns_timeentrywidget end_time]
<tr>
  <td align=right>Registration Deadline:
  <td>[_ns_dateentrywidget reg_deadline][_ns_timeentrywidget reg_deadline]
(at latest the Start Time)
<tr>
 <td align=right>Registration Cancellable?
 <td><select name=reg_cancellable_p>
     <option SELECTED value=\"t\">yes
     <option value=\"f\">no
     </select>
 (Can someone cancel his registration?)
<tr>
 <td align=right>Registration Needs Approval?
 <td><select name=reg_needs_approval_p>
     <option SELECTED value=\"t\">yes
     <option value=\"f\">no
     </select>
 (Does a registration need to be approved?)
<tr>
 <td align=right>Maximum Capacity:
 <td><input type=text size=20 name=max_people value=$max_people>
"


#<tr>
# <td align=right>Normal Price:
# <td><input type=text size=10 name=price value=$default_price>

ns_write "
<tr>
 <td align=left>Something to display <br>
after someone has registered <br>
for this event:
 <td><textarea name=display_after rows=8 cols=70 wrap=soft></textarea>
<tr>
 <td align=right>Refreshment Notes:
 <td><textarea name=refreshments_note rows=8 cols=70 wrap=soft></textarea>
<tr>
 <td align=right>Audio/Visual Notes:
 <td><textarea name=av_note rows=8 cols=70 wrap=soft></textarea>
<tr>
 <td align=right>Additional Notes:
 <td><textarea name=additional_note rows=8 cols=70 wrap=soft></textarea>

</table>

<br>
<br>

<center>
<input type=submit value=\"Add Event\">
</center>


[ad_footer]
"




