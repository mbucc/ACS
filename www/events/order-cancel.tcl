# events/order-cancel.tcl
# Purpose: Give users the option of cancelling a registration
#    (should only be for a cancellable event, but the check for that
#     happened elsewher and isn't repeated.)
#   TODO:  Check whether this event is cancel-able right here.
#####

ad_page_contract {
    Purpose: Give users the option of cancelling a registration
    (should only be for a cancellable event, but the check for that
    happened elsewher and isn't repeated.)

    @param reg_id the registration to cancel

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-cancel.tcl,v 3.8.2.4 2000/09/22 01:37:33 kevin Exp
} {
    {reg_id:integer,notnull}
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration


set whole_page ""
# build up the page to be returned

set reg_check [db_0or1row evnt_sel_reg "
    select r.user_id, a.short_name, p.event_id, e.reg_cancellable_p
      from events_registrations r, events_activities a, events_events e,
           events_prices p
     where r.reg_id = :reg_id
       and r.user_id = :user_id
       and e.event_id = p.event_id
       and p.price_id = r.price_id
       and a.activity_id = e.activity_id"]

if {!$reg_check} {
    db_release_unused_handles
    ad_return_warning "Invalid reg_id" "Registration $reg_id was not found in the database or does not belong
    to you."

    return
}

if {[string compare $reg_cancellable_p "f"] == 0} {
    ad_return_warning "Cannot Cancel Registration" "You 
    may not cancel your registration for this event."
    return
}

# ask user to confirm cancellation
append whole_page "
   [ad_header "Cancel Registration"]
<h2>Cancel Registration for $short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] "Cancel Registration"]
<hr>
<form method=post action=\"order-cancel-2\">
[export_form_vars reg_id]
Are you sure that you want to cancel this registration for
[events_pretty_event $event_id]?
<p>
<center> <input type=submit value=\"Yes, Cancel Registration\"> </center>
[ad_footer]
"

## clean up, return page.


doc_return  200 text/html $whole_page

##### EOF
