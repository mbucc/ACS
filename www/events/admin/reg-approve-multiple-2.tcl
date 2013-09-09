ad_page_contract {
    Approve multiple registrations.

    @param event_id the event whose multiple registrations we're approving
    @param state the state in which the multiple registrations are in

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-approve-multiple-2.tcl,v 3.4.2.4 2000/09/22 01:37:39 kevin Exp
} {
    {event_id:integer,notnull}
    {state:notnull}
}


page_validation {
    set err_msg ""
   
    if {$state != "waiting" && $state != "pending" && $state != "shipped"} {
	append err_msg "This page came in with an invalid state"
    }

    if {![empty_string_p $err_msg]} {
	error $err_msg
    }
}

set pretty_state [ad_decode $state "shipped" "Confirmed" "pending" "Pending" "waiting" "Wait-listed" $state]

set email_list [list]

#get the price_id
set price_id [db_string unused "select
price_id 
from events_prices where event_id = $event_id"]

db_transaction {
    #lock the table so that we know we're emailing everyone we approve
    db_dml lock_reg "lock table events_registrations in exclusive mode"

    #save the e-mail addresses of those we approve
    set email_list [db_list sel_email "
    select distinct u.email
    from events_registrations r, users u
    where r.price_id = :price_id
    and u.user_id = r.user_id
    and r.reg_state = :state
    "]

    #approve the users
    db_dml update_reg "update events_registrations
    set reg_state = 'shipped'
    where reg_state = :state
    and price_id = :price_id"

}

set from_email [db_string sel_from_email "select u.email
from users u, event_info ei, events_events e
where e.event_id = :event_id
and ei.group_id = e.group_id
and u.user_id = ei.contact_user_id"]

db_1row sel_event_info "select 
e.display_after, e.event_id,
v.description, v.venue_name
from events_events e, events_venues v
where e.event_id = :event_id
and v.venue_id = e.venue_id
"

set email_subject "Registration Approved"
set email_body "Your registration for:\n
[events_pretty_event $event_id]\n
has been approved.\n

$display_after\n

Venue description and directions:

$venue_name\n

$description\n

[ad_parameter SystemURL]/events/
"



doc_return  200 text/html "
[ad_header "Registration Approved"]
<h2>Registrants Approved</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Registrants Approved"]
<hr>
The [string tolower $pretty_state] registrants have been approved.
They will be notified by the following e-mail:
<p>
<pre>
From: $from_email
Subject: $email_subject

$email_body
</pre>
<p>
<a href=\"index\">Return to events administration</a>
[ad_footer]
"
ns_conn close

#actually send the e-mails now
foreach to_email $email_list {
    if [catch { ns_sendmail $to_email $from_email $email_subject $email_body } errmsg] {
	ns_log Notice "failed sending confirmation email to registrant: $errmsg"
    } 
    
}
