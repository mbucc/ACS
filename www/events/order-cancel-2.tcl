# events/order-cancel-2.tcl
# Purpose: Cancel a user's registration and verify that it's been done.
#####
 
ad_page_contract {
    Cancel a user's registration and verify that it's been done.

    @param reg_id the registration to cancel

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-cancel-2.tcl,v 3.8.2.6 2000/09/22 01:37:32 kevin Exp
} {
    {reg_id:naturalnum,notnull}
}


set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# collect the page to return
set whole_page ""

set reg_check [db_0or1row event_reg_check "
select e.reg_cancellable_p 
from events_registrations r, events_events e, events_prices p
where reg_id = :reg_id
and user_id = :user_id
and p.price_id = r.price_id
and e.event_id = p.event_id"]

if {!$reg_check} {
    db_release_unused_handles
    ad_return_warning "Could not find Registration" "Registration 
    $reg_id was not found in the database or does not belong
    to you."

    return
}

if {[string compare $reg_cancellable_p "f"] == 0} {
    ad_return_warning "Cannot Cancel Registration" "You 
    may not cancel your registration for this event."
    return
}

# else confirm the cancellation 
db_transaction {

if [catch {db_dml update_reg_cancel "update events_registrations
set reg_state = 'canceled'
where reg_id = :reg_id"} errmsg ] {
    ad_return_error "Could not cancel" "We were unable
    to cancel your registration due to an internal
    error.  Please notify the webmaster."
    return
}

#try to remove the user from the event's user group
set ug_check [db_0or1row evnt_remove_user "select
e.group_id as event_group_id, r.user_id as reg_user_id, e.event_id
from events_events e, events_registrations r, events_prices p
where r.reg_id = :reg_id
and p.price_id = r.price_id
and e.event_id = p.event_id"]

if {$ug_check} {
    db_dml user_delete "delete from user_group_map
    where group_id = :event_group_id
    and user_id = :reg_user_id
    and role <> 'administrator'"
}

}

append whole_page "
   [ad_header "Registration Canceled"]
<h2>Registration Canceled</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] "Register"]
<hr>
Your registration has been canceled.
<p>
<a href=\"index\">Return to events</a>
[ad_footer]
"

## clean up, return page.


doc_return  200 text/html $whole_page

##### EOF
