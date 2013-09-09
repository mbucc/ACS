# events/order-check.tcl
# Purpose: Allow users to check the status of an order/registration
#####

ad_page_contract {
    Allows users to check the status of an order/registration
    
    @param reg_id The registration to check

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-check.tcl,v 3.8.2.4 2000/09/22 01:37:33 kevin Exp
} {
    {reg_id:integer,notnull}
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set whole_page ""

set reg_check [db_0or1row sel_reg_info "
    select r.reg_state, p.event_id, r.user_id, a.short_name,
      a.description as activity_desc, e.start_time, e.end_time,
      to_char(e.start_time,'fmDay') as pretty_start_day, 
      to_char(e.end_time,'fmDay') as pretty_end_day,
      to_char(e.start_time,'HH12:MI AM') as pretty_start_hour_minute,
      to_char(e.end_time,'HH12:MI AM') as pretty_end_hour_minute
     from events_registrations r, events_activities a, events_events e,
           events_prices p
     where r.reg_id = :reg_id
       and r.user_id = :user_id
       and e.event_id = p.event_id
       and p.price_id = r.price_id
       and a.activity_id = e.activity_id"]

if {!$reg_check} {
    db_release_unused_handles
    
    ad_return_warning "Could Not Find Registration" "
    Registration $reg_id was not found in the database or does not belong
    to you. "
    return
}

# we have a valid reg id

db_1row evnt_sel_event_info "
select e.display_after, v.description as venue_desc, v.venue_name,
v.venue_id
from events_events e, events_venues v
where v.venue_id = e.venue_id
and e.event_id = :event_id"

# else return the status of the appropriate registration
append whole_page "
  [ad_header "Status of Registration"]

<h2>Status of Registration for $short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] "Registration Status"]
<hr>
"

if {$reg_state == "canceled"} {
    set status_sentence "Your registration has been canceled.  If you want, you
may <a href=\"order-one?event_id=$event_id\">place a new registration</a>."    
} elseif { $reg_state == "shipped" } {
    set status_sentence "Your place is reserved. <p>
       $display_after
       <h3>Directions to $venue_name</h3>
       $venue_desc
    "
} elseif { $reg_state == "pending" } {
    set status_sentence "We have received your registration and are currently
 reviewing it to decide if it will be approved.  We will notify you
 by e-mail once your registrating status changes."
} elseif { $reg_state == "waiting" } {
    set status_sentence "You are on the waiting list for this event.  We will
 notify you by e-mail if your registration status changes."
}

## clean up, return page.

append whole_page "\n $status_sentence \n 
<h3>About $short_name</h3>
<ul>
<p><li>Start Time:  $pretty_start_day, [util_AnsiDatetoPrettyDate $start_time],
[string trimleft $pretty_start_hour_minute "0"]
<li>End Time:  $pretty_end_day, [util_AnsiDatetoPrettyDate $end_time], 
[string trimleft $pretty_end_hour_minute "0"]
<li>Location: [events_pretty_venue $venue_id]
</ul>
<p>
$activity_desc
[ad_footer]"


doc_return  200 text/html $whole_page

##### EOF
