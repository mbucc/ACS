set user_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables
#reg_id

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select 1 from
events_registrations
where reg_id = $reg_id
"]

ReturnHeaders

if {[empty_string_p $selection]} {
    ns_write "
    [ad_header "Could not find registration"]
    <h2>Couldn't find registration</h2>
    <a href=\"index.tcl\">[ad_system_name] events</a> 
    <hr>
    Registration $reg_id was not found in the database.

    [ad_footer]"

    return
}

ns_db dml $db "update events_registrations
set reg_state = 'shipped'
where reg_id = $reg_id"

set to_email [database_to_tcl_string $db "select 
u.email
from users u, events_registrations r
where r.reg_id = $reg_id
and u.user_id = r.user_id"]

ns_write "[ad_header "Registration Approved"]
<h2>Registration Approved</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Order History"]
<hr>
$to_email's registration has been approved.
<p>
<a href=\"index.tcl\">Return to events administration</a>
[ad_footer]
"

ns_conn close

#e-mail the registrant to let him know we canceled his registration
set from_email [database_to_tcl_string $db "select email from
users where user_id = $user_id"]

set selection [ns_db 1row $db "select 
u.email as to_email, e.display_after, e.event_id,
v.description, v.venue_name
from users u, events_registrations r, events_prices p,
events_events e, events_venues v
where r.reg_id = $reg_id
and u.user_id = r.user_id
and p.price_id = r.price_id
and e.event_id = p.event_id
and v.venue_id = e.venue_id
"]

set_variables_after_query

set email_subject "Registration Approved"
set email_body "Your registration for:\n
[events_pretty_event $db $event_id]\n
has been approved.\n

$display_after\n

Venue description and directions:

$venue_name\n

$description\n

[ad_parameter SystemURL]/events/
"

if [catch { ns_sendmail $to_email $from_email $email_subject $email_body } errmsg] {
    ns_log Notice "failed sending confirmation email to customer: $errmsg"
} 
