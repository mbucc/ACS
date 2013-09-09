# events/admin/event.tcl
# Purpose:  List one event with details, for administration.
#   (that is, with links for altering and updating the event info)
###

ad_page_contract {
    Purpose:  List one event with details, for administration.
    (that is, with links for altering and updating the event info)

    @param event_id the event at which we're looking

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event.tcl,v 3.15.2.5 2000/09/22 01:37:37 kevin Exp
} {
    {event_id:integer,notnull}
}

# prepare page to return
set whole_page ""



set event_check [db_0or1row event_info "select 
    a.activity_id, a.short_name, e.display_after, v.city, 
    decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location,
    to_char(start_time, 'fmDay, fmMonth DD, YYYY') as compact_date, 
    to_char(start_time, 'YYYY-MM-DD HH24:MI') as start_pretty_time, 
    to_char(end_time, 'YYYY-MM-DD HH24:MI') as end_pretty_time,
    to_char(reg_deadline, 'YYYY-MM-DD HH24:MI') as deadline_pretty_time,  
    u.first_names || ' ' || u.last_name as creator_name,
    e.available_p, e.max_people, e.refreshments_note, e.av_note,
    e.additional_note,
    decode(e.reg_cancellable_p,
       't', 'yes',
       'f', 'no',
       'no') as reg_cancellable_p,
    decode (e.reg_needs_approval_p,
       't', 'yes',
       'f', 'no',
       'no') as reg_needs_approval_p
    from events_events e, events_activities a, users u, events_venues v,
         country_codes cc
   where e.event_id = :event_id
     and e.activity_id = a.activity_id
     and v.venue_id = e.venue_id
     and u.user_id = e.creator_id
     and cc.iso = v.iso
"]

if {!$event_check} {
    ad_return_error "Invalid event_id" "This page came without
    a valid event id"
    return
}

set pretty_location "$city, $big_location"

append whole_page "[ad_header "$pretty_location: $compact_date"]"

append whole_page "
   <h2>$pretty_location: $compact_date</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Event"]
<hr>

<ul>
"

set n_orders [db_string sel_reg_count "select count(*) 
   from events_reg_not_canceled e, events_prices p
  where p.price_id = e.price_id
    and p.event_id = :event_id "]

set sql_post_select "select distinct
users.email, users.user_id, users.email_type
from users_spammable users, events_reg_not_canceled r, events_prices p
   where p.event_id = $event_id
     and users.user_id = r.user_id
     and p.price_id = r.price_id 
order by users.user_id
"

if { $n_orders > 1 } {
    append whole_page "<li><a href=\"order-history-one.tcl?event_id=$event_id&history_type=event\">View All $n_orders Orders for this Event</a>\n
"
} elseif { $n_orders == 1 } {
    append whole_page "<li><a href=\"order-history-one.tcl?event_id=$event_id&history_type=event\">View the Single Order for this Event</a>\n
"
} else {
    append whole_page "<li>There have been no orders for this event\n"
}

set contact_email [db_string sel_contact_email "select
u.email 
from users u, event_info ei, events_events e
where e.event_id = :event_id
and ei.group_id = e.group_id
and u.user_id = ei.contact_user_id" -default "" ]

append whole_page "<li><a href=\"/events/order-one?event_id=$event_id\">View the page that users see</a>
<li><a href=\"spam-selected-events?event_id=$event_id\">Spam this event's registrants</a>

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
 <th valign=top>Event Contact Person
 <td valign=top>$contact_email
<tr>
  <th valign=top>Availability Status</th>
"
if {[string compare $available_p "t"] == 0} {
    append whole_page "<td valign=top>Current"
} else {
    append whole_page "<td valign=top>Discontinued"
}

append whole_page " &nbsp; (<a href=\"event-toggle-available-p?event_id=$event_id\">toggle</a>)
"
if {[string compare $available_p "f"] == 0 && $n_orders > 0} {
    append whole_page "
    <br><font color=red>You may want to 
    <a href=\"spam/action-choose?[export_url_vars sql_post_select]\">spam the registrants for this event</a>
    to notify them the event is canceled.</font>"
}

append whole_page "
 </table>
<ul>
 <li><a href=\"event-edit?[export_url_vars event_id]\">
     Edit Event Properties</a></ul>
"

### We leave the pricing section out for now;
### hooks into the e-commerce module aren't done yet.
#append whole_page "
#<h3>Pricing</h3>
#<ul>
#"

#set selection [ns_db select $db "select
#    price_id, description as product_name,
#    decode (price, 0, 'free', price) as pretty_price, 
#    description, available_date,
#    expire_date
#  from events_prices
# where event_id = $event_id"]
#
#while {[ns_db getrow $db $selection]} {
#    set_variables_after_query
#
#    if {$pretty_price != "free"} {
#	set pretty_price  $[util_commify_number $pretty_price]
#    }
#
#    append whole_page "<li>
#    <a href=\"event-price-ae?[export_url_vars event_id price_id]\">
#    $product_name</a>: $pretty_price
#    (available [util_AnsiDatetoPrettyDate $available_date] to
#    [util_AnsiDatetoPrettyDate $expire_date])"
#}
#
#append whole_page "
#<br><br>
#<li><a href=\"event-price-ae?[export_url_vars event_id]\">
#Add a special price</a> 
#(student discount, late price, etc.)
#</ul>"
###

### Display custom field info, and allow insertion and deletion
### of these fields.  
append whole_page "
  <h3>Custom Fields</h3>
You may define custom fields that you would like to
collect from registrants.
<p>
<table>
"

set number_of_fields [db_string sel_num_fields "select count(*) from events_event_fields where event_id=:event_id"]

set counter 0 

db_foreach sel_event_fields "select 
         column_name, pretty_name, column_type, column_actual_type,
         column_extra, sort_key
    from events_event_fields
   where event_id = :event_id
   order by sort_key " {
    incr counter 
    if { $counter == $number_of_fields } {
	append whole_page "
<tr><td><ul>
        <li>$column_name ($pretty_name), $column_actual_type ($column_type) $column_extra
    <td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"event-field-add?event_id=$event_id&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"event-field-delete?[export_url_vars event_type column_name event_id]\">delete</a>&nbsp;\]</font></ul>\n"
    } else {
	append whole_page "<tr>
    <td><ul><li>$column_name ($pretty_name), $column_actual_type ($column_type) $column_extra
    <td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"event-field-add?event_id=$event_id&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"event-field-swap?event_id=$event_id&sort_key=$sort_key\">swap&nbsp;with&nbsp;next</a>&nbsp;|&nbsp;<a href=\"event-field-delete?[export_url_vars event_id column_name]\">delete</a>&nbsp;\]</font></ul>\n"
    }
}

if { $counter == 0 } {
    append whole_page "
     <tr><td><ul><li>no custom fields currently collected</ul>
    "
}

append whole_page "
 </table>
<p>
<ul>
<li><a href=\"event-field-add?[export_url_vars event_id]\">add a field</a>
</ul>
"

### Section for special roles associated with this event.
append whole_page "<h3>Organizers</h3>\n <ul>"

set org_counter 0
db_foreach sel_evnt_organizers "select 
eo.role, eo.user_id, eo.role_id, 
decode(eo.public_role_p, 't', '(public role)', '') as public_role_p,
u.first_names || ' ' || u.last_name as organizer_name
from events_organizers eo, users u
where eo.event_id=$event_id
and eo.user_id = u.user_id(+)
order by role
" {
    append whole_page "<li><a href=\"organizer-role-ae?[export_url_vars role_id event_id]\">$role:</a> $organizer_name $public_role_p\n"
    incr org_counter
}

if {$org_counter == 0} {
    append whole_page "<li>There are no organizers for this event"
}

set sql_post_select "select distinct
   users.email, users.user_id, users.email_type
   from users_spammable users, events_organizers eo
  where eo.event_id = $event_id
    and users.user_id = eo.user_id
order by users.user_id
"

append whole_page "
<p>
<li><a href=\"organizer-role-ae?[export_url_vars event_id]\">Add a new organizer role</a>
"
if {$org_counter > 0} {
    append whole_page "<li><a href=\"spam/action-choose?[export_url_vars sql_post_select]\">Spam all the organizers for this event</a>"
}

append whole_page "</ul>"

set return_url "/events/admin/event.tcl?event_id=$event_id"
set on_which_table "events_events"
set on_what_id "$event_id"

append whole_page "<h3>Agenda Files</h3>\n <ul>"

set agenda_count 0
db_foreach sel_agendas "
  select file_title, file_id 
    from events_file_storage
   where on_which_table = :on_which_table
     and on_what_id = :on_what_id" {
    incr agenda_count
    append whole_page "<li>
     <a href=\"attach-file/download?[export_url_vars file_id]\">
     $file_title</a> |
     <a href=\"attach-file/file-remove?[export_url_vars file_id return_url]\">
     Remove this file\n
    "
}

if {$agenda_count == 0} {
    append whole_page "<li>There are no agenda files for this event"
}

append whole_page "<br><br>
  <li><a href=\"attach-file/upload?[export_url_vars return_url on_which_table on_what_id]\">Upload an agenda file</a>
</ul>
"

set group_link [ad_urlencode [db_string sel_short_name "select
        ug.short_name from user_groups ug, events_events e
  where ug.group_id = e.group_id
    and e.event_id = :event_id"]]

append whole_page "<h3>Event User Group</h3>
 You may manage the user group for this event.
 <ul>
  <li><a href=\"/groups/admin/$group_link/\">Manage this event's user
group</a>
 </ul>
"

## Leave this out for now
#set selection [ns_db select $db "select 1 from
#events_calendar_seeds
#where activity_id = $activity_id"]

#if {![empty_string_p $selection]} {
#    append whole_page "<h3>Event Calendars</h3>
#    This event's activity has a default calendar.  You may populate
#    this event's calendar or the site calendar based upon this default
#    activity calendar.
#    <p>
#    <ul>
#    <li><a href=\"calendars/index?[export_url_vars event_id]\">Manage event calendars</a>
#    </ul>
#    "
#}

append whole_page "
  <h3>Event Notes</h3>
<table>
<tr>
  <th valign=top>Refreshments Note</th>
  <td><form method=POST action=\"event-update-refreshments-note\">
      [export_form_vars event_id]
      <textarea name=refreshments_note rows=6 cols=65 wrap=soft>$refreshments_note</textarea>
      <br>
      <input type=submit value=\"Update\">
      </form>
</tr>
<tr>
  <th valign=top>Audio/Visual Note</th>
  <td><form method=POST action=\"event-update-av-note\">
      [export_form_vars event_id]
      <textarea name=av_note rows=6 cols=65 wrap=soft>$av_note</textarea>
      <br>
      <input type=submit value=\"Update\">
      </form>
</tr>
<tr>
  <th valign=top>Additional Note</th>
  <td><form method=POST action=\"event-update-additional-note\">
      [export_form_vars event_id]
      <textarea name=additional_note rows=6 cols=65 wrap=soft>$additional_note</textarea>
      <br>
      <input type=submit value=\"Update\">
      </form>
</tr>
</table>
[ad_footer]"

## clean up and return the page



doc_return  200 text/html $whole_page

##### EOF
