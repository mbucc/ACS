# File:  events/admin/reg-approve-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose: Update registration status for one registration
#####

ad_page_contract {
    Updates registration status for one registration to 'shipped'

    @param reg_id the registration we're approving

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-approve-2.tcl,v 3.10.2.5 2000/09/22 01:37:39 kevin Exp
} {
    {reg_id:integer,notnull}
}    

set user_id [ad_maybe_redirect_for_registration]

set reg_check [db_0or1row check_reg "
select '1_reg_check'
from events_registrations
where reg_id = :reg_id"]

if {!$reg_check} {
    append whole_page "
    [ad_header "Could not find registration"]
    <h2>Couldn't find registration</h2>
    <a href=\"index\">[ad_system_name] events</a> 
    [ad_context_bar_ws [list "index.tcl" "Events Administration"] "Registration Approval"]
    <hr>
    Registration $reg_id was not found in the database.

    [ad_footer]"

    return
}

#set the reg_state to be shipped
db_transaction {
    db_dml update_reg "update events_registrations
    set reg_state = 'shipped'
    where reg_id = :reg_id"

    #add this person to the event's user group
    db_1row sel_ug "select
    r.user_id as reg_user_id, p.event_id
    from events_registrations r, events_prices p
    where r.reg_id = :reg_id
    and p.price_id = r.price_id"

    events_group_add_user $event_id $reg_user_id
}

set to_email [db_string sel_to_email "
 select u.email
   from users u, events_registrations r
  where r.reg_id = :reg_id
    and u.user_id = r.user_id"]

append whole_page "[ad_header "Registration Approved"]
<h2>Registration Approved</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Registration Approval"]
<hr>
$to_email's registration has been approved.  $to_email has been notified by 
e-mail:
"
#e-mail the registrant to let him know we canceled his registration
#set from_email [db_string unused "select email from
#users where user_id = $user_id"]

set from_email [db_string sel_from_email "select u.email
from users u, event_info ei, events_events e
where e.event_id = :event_id
and ei.group_id = e.group_id
and u.user_id = ei.contact_user_id"]

db_1row sel_event_info "select 
u.email as to_email, e.display_after, e.event_id,
e.start_time, e.end_time,
to_char(e.start_time, 'fmHH:fmMI AM') as pretty_start_time,
to_char(e.end_time, 'fmHH:fmMI AM') as pretty_end_time,
v.description, v.venue_name,
a.short_name
from users u, events_registrations r, events_prices p,
events_events e, events_venues v,
events_activities a
where r.reg_id = :reg_id
and u.user_id = r.user_id
and p.price_id = r.price_id
and e.event_id = p.event_id
and v.venue_id = e.venue_id
and a.activity_id = e.activity_id
"

set email_subject "Registration Approved"
set email_body "Your registration for:\n
$short_name from [util_AnsiDatetoPrettyDate $start_time] $pretty_start_time to [util_AnsiDatetoPrettyDate $end_time] $pretty_end_time\n
has been approved.\n

[util_striphtml $display_after]\n

Venue description and directions:

$venue_name\n

[util_striphtml $description]\n

If you would like to cancel your order, you may visit
[ad_parameter SystemURL]/events/order-cancel.tcl?[export_url_vars reg_id]

Information for this event is located at
[ad_parameter SystemURL]/events/event-info.tcl?[export_url_vars event_id]
"
append whole_page "
<pre>
To: $to_email
From: $from_email
Subject: $email_subject

$email_body
</pre>
<p>
<a href=\"index\">Return to events administration</a>
[ad_footer]
"


doc_return  200 text/html $whole_page

ns_conn close

if [catch { ns_sendmail $to_email $from_email $email_subject $email_body } errmsg] {
    ns_log Notice "failed sending confirmation email to customer: $errmsg"
} 

##### EOF
