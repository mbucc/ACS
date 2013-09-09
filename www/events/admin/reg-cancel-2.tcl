# File:  events/admin/reg-cancel-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Cancel one registration
#####

ad_page_contract {
    Cancels a registration.

    @param reg_id the registration to cancel
    @param cancel_reason why we are canceling this reg

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-cancel-2.tcl,v 3.9.2.5 2000/09/22 01:37:39 kevin Exp
} {
    {reg_id:integer,notnull}
    {cancel_reason:html,trim,optional}
}

set user_id [ad_maybe_redirect_for_registration]

if {![exists_and_not_null cancel_reason]} {
    set cancel_msg ""
} else {
    set cancel_msg "Explanation:\n\n"

    # Strip all ^M's out of any interactively entered text message.
    # This is because Windows browsers insist on inserting CRLF at
    # the end of each line of a TEXTAREA.
    regsub -all "\r" $cancel_reason "" cancel_reason
    append cancel_msg $cancel_reason
}



set reg_check [db_0or1row sel_reg "select '1_reg_check' from
events_registrations
where reg_id = :reg_id
"]

if {!$reg_check} {
    append whole_page "
    [ad_header "Could not find registration"]
    <h2>Couldn't find registration</h2>
    [ad_context_bar_ws [list "index.tcl" "Events Administration"] "Cancel Registration"]
    <hr>

    Registration $reg_id was not found in the database.
    [ad_footer]"

    return
}

#cancel the registration
db_transaction {
    db_dml update_reg "update events_registrations
    set reg_state = 'canceled'
    where reg_id = :reg_id"

    #try to remove the user from the event's user group
    set user_check [db_0or1row sel_user_info "select
    e.group_id as event_group_id, r.user_id as reg_user_id, e.event_id
    from events_events e, events_registrations r, events_prices p
    where r.reg_id = :reg_id
    and p.price_id = r.price_id
    and e.event_id = p.event_id"]

    if {$user_check > 0} {
	db_dml del_ugm "delete from user_group_map
	where group_id = :event_group_id
	and user_id = :reg_user_id
	and role <> 'administrator'"
    }

}

set to_email [db_string sel_to_email "
 select u.email
   from users u, events_registrations r
  where r.reg_id = :reg_id
    and u.user_id = r.user_id"]

append whole_page "[ad_header "Registration Canceled"]
<h2>Registration Canceled</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Cancel Registration"]
<hr>

$to_email's registration has been canceled.  $to_email has been notified
by e-mail:
"

#e-mail the registrant to let him know we canceled his registration
#set from_email [db_string unused "select email from
#users where user_id = $user_id"]
set from_email [db_string sel_from_email "select u.email
from users u, event_info ei, events_events e
where e.event_id = :event_id
and ei.group_id = e.group_id
and u.user_id = ei.contact_user_id"]

set to_email [db_string sel_to_email_addr "
 select u.email
   from users u, events_registrations r
  where r.reg_id = :reg_id
    and u.user_id = r.user_id"]

set event_id [db_string sel_event_id "
 select event_id
   from events_registrations r, events_prices p
  where r.reg_id = :reg_id
    and p.price_id = r.price_id"]

set email_subject "Registration Canceled"
set email_body "Your registration for:\n
[events_pretty_event $event_id]\n
has been canceled.\n

$cancel_msg

[ad_parameter SystemURL]/events/
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
