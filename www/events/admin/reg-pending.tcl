set_the_usual_form_variables
#event_id

set db [ns_db gethandle]

if {![exists_and_not_null event_id]} {
    ad_return_error "No event_id" "This page came in without an event_id"
    return
}

ReturnHeaders
ns_write "[ad_header "Pending Registrations"]
<h2>Pending Registrations for [events_pretty_event $db $event_id]</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Pending Registrations"]

<hr>
<ul>
"

set selection [ns_db select $db "select 
r.reg_id, email, reg_date
from events_registrations r, users u, events_prices p
where p.event_id = $event_id
and r.price_id = p.price_id
and u.user_id = r.user_id
and reg_state='pending'
order by reg_date asc
"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    ns_write "<li><a href=\"reg-view.tcl?[export_url_vars reg_id] \">
    $email ([util_AnsiDatetoPrettyDate $reg_date])</a>"
}

ns_write "</ul> [ad_footer]"

    