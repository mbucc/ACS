set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_the_usual_form_variables
# we expect to get one argument:  reg_id

if {![exists_and_not_null reg_id] } {
    ns_return 200 text/html "[ad_header "No registration id"]

<h2>No registration id</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] Register]
<hr>

Registration id needed.  This request came in with no
registration id.

[ad_footer]
"
    return
}

set db [ns_db gethandle]

# We will only give them reg_state for the privacy of
# the customers (i.e. we don't want to return a customer's
# name if somebody is typing in random reg id's).
set selection [ns_db 0or1row $db "select r.reg_state, 
p.event_id, 
r.user_id, a.short_name
from events_registrations r, events_activities a, events_events e,
events_prices p
where r.reg_id = $reg_id
and r.user_id = $user_id
and e.event_id = p.event_id
and p.price_id = r.price_id
and a.activity_id = e.activity_id
"]


if { $selection == "" } {
     ns_return 200 text/html "[ad_header "Could not find registration"]

<h2>Could not find registration</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] Register]
<hr>

Registration $reg_id was not found in the database or does not belong
to you.

[ad_footer]
"
    return
}

# we have a valid reg id

set_variables_after_query

#collect the whole page for output
set whole_page "[ad_header "Status of Registration"]

<h2>Status of Registration for $short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] Register]
<hr>
"

if {$reg_state == "canceled"} {
    set status_sentence "Your registration has been canceled.  If you want, you
    may <a href=\"order-one.tcl?event_id=$event_id\">place a new registration</a>."    
} elseif { $reg_state == "shipped" } {
    set selection [ns_db 1row $db "select
    display_after, v.description, v.venue_name
    from events_events e, events_venues v
    where v.venue_id = e.venue_id
    and e.event_id = $event_id"]
    
    set_variables_after_query

    set status_sentence "Your place is reserved.
    <p>
    $display_after
    <h3>Directions to $venue_name</h3>
    $description
"
} elseif { $reg_state == "pending" } {
    set status_sentence "We have received your registration and are currently
    reviewing it to decide if it will be approved.  We will notify you
    by e-mail once your registrating status changes."
} elseif { $reg_state == "waiting" } {
    set status_sentence "You are on the waiting list for this event.  We will
    notify you by e-mail if your registration status changes."
}

append whole_page "

$status_sentence

[ad_footer]
"

ns_db releasehandle $db
ReturnHeaders
ns_write $whole_page