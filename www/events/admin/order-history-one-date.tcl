set admin_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables
# reg_date

ReturnHeaders

ns_write "[ad_header "Orders for [util_IllustraDatetoPrettyDate $reg_date]"]

<h2>Orders for [util_IllustraDatetoPrettyDate $reg_date]</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Date"]

<hr>

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select r.reg_id,
r.reg_state, u.first_names, u.last_name, a.short_name
from events_registrations r, events_activities a, events_events e, users u,
events_prices p, user_group_map ugm
where trunc(reg_date) = '$reg_date'
and e.activity_id = a.activity_id
and p.event_id = e.event_id
and u.user_id = r.user_id
and a.group_id = ugm.group_id
and ugm.user_id = $admin_id
and p.price_id = r.price_id
union
select r.reg_id,
r.reg_state, u.first_names, u.last_name, a.short_name
from events_registrations r, events_activities a, events_events e, users u,
events_prices p
where trunc(reg_date) = '$reg_date'
and e.activity_id = a.activity_id
and p.event_id = e.event_id
and u.user_id = r.user_id
and a.group_id is null
and p.price_id = r.price_id
order by reg_id desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "\n<li>"
    events_write_order_summary
}
  
ns_write "
</ul>

[ad_footer]
"




