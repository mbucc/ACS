# events/admin/event-edit.tcl
# Purpose:  Allows admins to edit an event's properties.
#           Provides a form with existing data filled in.
###

ad_page_contract {
    Allows admins to edit an event's properties.
    Provides a form with existing data filled in.

    @param event_id the event to edit
    @param venue_id the event's new venue (if changing the venue)
    @param user_id_from_search optional new contact person's user_id
    @param email_from_search optional new contact person's email

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-edit.tcl,v 3.10.2.4 2000/09/22 01:37:36 kevin Exp
} {
    {event_id:integer,notnull}
    {venue_id:integer,optional}
    {user_id_from_search:integer,optional}
    {email_from_search:optional}
}

db_1row event_info "
  select a.short_name, a.activity_id, v.venue_id as old_venue_id,
         e.display_after, e.start_time, e.max_people,
         to_char(e.start_time,'YYYY-MM-DD HH24:MI:SS') as start_timestamp, 
         to_char(e.end_time,'YYYY-MM-DD HH24:MI:SS') as end_timestamp,
         to_char(e.reg_deadline,'YYYY-MM-DD HH24:MI:SS') as deadline_timestamp,
         reg_cancellable_p, reg_needs_approval_p
    from events_events e, events_venues v, events_activities a
   where e.event_id= :event_id
     and v.venue_id = e.venue_id
     and a.activity_id = e.activity_id "

if {![exists_and_not_null venue_id]} {
    set venue_id $old_venue_id
}

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

#initialize the page to be returned
set whole_page ""

set return_url "event-edit.tcl?event_id=$event_id"

#release the handle for ad_header
append whole_page "
[ad_header "Edit Event"]"

#see if the contact email came from a search
if {[exists_and_not_null email_from_search]} {
    set contact_email $email_from_search
    set contact_user_id $user_id_from_search
} else {
    db_1row sel_contact_info "select
    u.email as contact_email, ei.contact_user_id 
    from users u, event_info ei, events_events e
    where e.event_id = :event_id
    and ei.group_id = e.group_id
    and u.user_id = ei.contact_user_id"
}
set return_url "/events/admin/event-edit.tcl"

append whole_page "
<h2>Edit Event</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] [list "event.tcl?[export_url_vars event_id]" "Event"] "Edit Event"]
<hr>

$short_name on [util_AnsiDatetoPrettyDate $start_time]
<form method=POST action=event-edit-2?event_id=$event_id>
[export_form_vars event_id]
<table>
<tr>
  <th align=right>Venue:
  <td>[events_venues_widget $venue_id 1]
  <td align=left><a href=\"venues-ae?[export_url_vars return_url]\">Add a New Venue</a>
<tr>
 <th align=right>Maximum Capacity:
 <td><input type=text size=20 name=max_people value=$max_people>
<tr>
 <th align=right>Registration Cancellable?
 <td><select name=reg_cancellable_p>
"

if {$reg_cancellable_p == "t"} {
    append whole_page "
    <option SELECTED value=\"t\">yes
    <option value=\"f\">no"
} else {
    append whole_page "
    <option value=\"t\">yes
    <option SELECTED value=\"f\">no"
}
append whole_page "
    </select>
 (Can someone cancel his registration?)
<tr>
 <th align=right>Registration Needs Approval?
 <td><select name=reg_needs_approval_p>
"

if {$reg_needs_approval_p == "t"} {
    append whole_page "
     <option SELECTED value=\"t\">yes
     <option value=\"f\">no"
} else {
    append whole_page "
     <option value=\"t\">yes
     <option SELECTED value=\"f\">no"
}
append whole_page "
     </select>
 (Does a registration need to be approved?)
<tr>
 <th align=right>Event Contact Person
 <td>$contact_email <a href=\"event-contact-find?[export_url_vars return_url event_id]\">
     Pick a different contact person</a>
<input type=hidden name=contact_user_id value=$contact_user_id>
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

## clean up, return page



doc_return  200 text/html $whole_page
##### EOF 

