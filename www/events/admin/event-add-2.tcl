# File:  events/admin/event-add-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose: allow an admin to insert info for a new event, one a
#   venue has been chosen.
#####

ad_page_contract {
    Purpose: allow an admin to insert info for a new event, one a
    venue has been chosen.

    @param activity_id the activity type of the new event
    @param venue_id where the new event will be located

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-add-2.tcl,v 3.9.2.5 2001/01/10 18:18:55 khy Exp
} {
    {activity_id:integer,notnull}
    {venue_id:integer,notnull}
}

set user_id [ad_maybe_redirect_for_registration]

# append to a page and return it even though there's just
# one real ns_write for now. 
set whole_page ""



set event_id [db_string evnt_id_seq "select events_event_id_sequence.nextval from dual"]

# no ecommerce yet
#set new_product_id [db_string unused "select ec_product_id_sequence.nextval from dual"]

set price_id [db_string price_id_seq "select events_price_id_sequence.nextval from dual"]

db_1row activity_info "select 
short_name as activity_name,
default_contact_user_id,
default_price 
from events_activities where activity_id = :activity_id"

db_1row venue_info "select venue_id, max_people
from events_venues where venue_id=:venue_id"

#make the time elements only show minutes--not down to the second
set time_now [db_string sel_sysdate "select
to_char(sysdate, 'YYYY-MM-DD HH24:MI') from dual"]

set time_elements "<tr>
  <td align=right>Start:
  <td>[_ns_dateentrywidget start_time] [_ns_timeentrywidget start_time]
<tr>
  <td align=right>End:
  <td>[_ns_dateentrywidget end_time][_ns_timeentrywidget end_time]
<tr>
  <td align=right>Registration Deadline:
  <td>[_ns_dateentrywidget reg_deadline][_ns_timeentrywidget reg_deadline]
(at latest the Start Time)
"
set stuffed_with_start [ns_dbformvalueput $time_elements "start_time" "timestamp" $time_now]
set stuffed_with_se [ns_dbformvalueput $stuffed_with_start "end_time" "timestamp" $time_now]
set stuffed_with_all_times [ns_dbformvalueput $stuffed_with_se "reg_deadline" "timestamp" $time_now]

append whole_page "[ad_header "Add a New Event"]
  <h2>Add a New Event for $activity_name</h2>

  [ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] [list "activity.tcl?[export_url_vars activity_id]" Activity] "Add Event"]
<hr>

<form method=get action=event-add-3>
[export_form_vars activity_id venue_id]
[export_form_vars -sign event_id price_id]

<table>
<tr>
 <td align=right>Location:
 <td>[events_pretty_venue_name $venue_id]
$stuffed_with_all_times
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
 <td>
 <td>
(The max number of people that can register before new registrants
are automatically wait-listed.  If this field is empty, wait-listing won't
automatically kick in.)
<tr>
 <td align=right>Maximum Capacity:
 <td><input type=text size=20 name=max_people value=$max_people>
"

set return_url "/events/admin/event-add-2.tcl"

#see if the contact email came from a search
if {[exists_and_not_null email_from_search]} {
    set contact_email $email_from_search
    set contact_user_id $user_id_from_search
} elseif {[exists_and_not_null default_contact_user_id]} {
    set contact_email [db_string sel_contact_email "select
    email from users 
    where user_id = :default_contact_user_id"]
    set contact_user_id $default_contact_user_id
} else {
    #user the event creator 
    set contact_email [db_string sel_creator_id "select 
    email from users
    where user_id = :user_id"]
    set contact_user_id $user_id
}

append whole_page "
<tr>
 <td>
 <td>(the e-mail account from which automated
 e-mails for this event is sent)
<tr>
 <td align=right>Event Contact Person:
 <td>$contact_email  <a href=\"event-contact-find?[export_url_vars return_url activity_id venue_id]\">
     Pick a different contact person</a>
<input type=hidden name=contact_user_id value=$contact_user_id>
"

#<tr>
# <td align=right>Normal Price:
# <td><input type=text size=10 name=price value=$default_price>

append whole_page "
<tr>
 <td align=left>Something to display <br>
after someone has registered <br>
for this event<br>(don't need directions, no html):
 <td><textarea name=display_after rows=8 cols=70 wrap=soft>Thanks for registering for $activity_name!
</textarea>
<tr>
 <td align=left colspan=2><i>Below Notes are for 
 event administrators to see</i>
<tr>
 <td align=right>Refreshment Notes:
 <td><textarea name=refreshments_note rows=8 cols=70 wrap=soft></textarea>
<tr>
 <td align=right>Audio/Visual Notes:
 <td><textarea name=av_note rows=8 cols=70 wrap=soft></textarea>
<tr>
 <td align=right>Additional Notes:
 <td><textarea name=additional_note rows=8 cols=70 wrap=soft></textarea>

</table> <br><br>

<center> <input type=submit value=\"Add Event\"> </center>

[ad_footer]
"

# return page


doc_return  200 text/html $whole_page
##### EOF
