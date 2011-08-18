set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_the_usual_form_variables
#reg_id

set db [ns_db gethandle]

ReturnHeaders

set selection [ns_db 0or1row $db "select r.user_id, a.short_name,
p.event_id
from events_registrations r, events_activities a, events_events e,
events_prices p
where r.reg_id = $reg_id
and r.user_id = $user_id
and e.event_id = p.event_id
and p.price_id = r.price_id
and a.activity_id = e.activity_id"]

if {[empty_string_p $selection]} {
    ns_db releasehandle $db
    ns_write "
    [ad_header "Could not find registration"]
    <h2>Could not find registration</h2>
    [ad_context_bar_ws [list "index.tcl" "Events"] Register]
    <hr>
    Registration $reg_id was not found in the database or does not belong
    to you.

    [ad_footer]"

    return
}

set_variables_after_query

#collect the page for output
set whole_page "
[ad_header "Cancel Registration"]
<h2>Cancel Registration for $short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] Register]
<hr>
<form method=post action=\"order-cancel-2.tcl\">
[export_form_vars reg_id]
Are you sure that you want to cancel this registration for
[events_pretty_event $db $event_id]?
<p>
<center>
<input type=submit value=\"Yes, Cancel Registration\">
</center>
[ad_footer]
"

ns_db releasehandle $db
ReturnHeaders
ns_write $whole_page