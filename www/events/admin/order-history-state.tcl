set admin_id [ad_maybe_redirect_for_registration]

ReturnHeaders

ns_write "[ad_header "[ad_system_name] Events Administration: Order History - By Order State"]

<h2>Order History - By Registration State</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Registration State"]

<hr>

<table border=2 cellpadding=5>
<tr>
<th align=center>Registration State
<th align=center>Registrations
"

set db [ns_db gethandle]

# count the number of orders (in events_registrations) for each order_state in 
# events_registrations

set selection [ns_db select $db "select 
reg_state, count(reg_id) as n_orders
from events_registrations r, events_activities a, events_events e,
events_prices p,
user_group_map ugm
where p.event_id = e.event_id
and p.price_id = r.price_id
and e.activity_id = a.activity_id
and a.group_id = ugm.group_id
and ugm.user_id = $admin_id
group by reg_state
union
select 
reg_state, count(reg_id) as n_orders
from events_registrations r, events_activities a, events_events e,
events_prices p
where p.event_id = e.event_id
and p.price_id = r.price_id
and e.activity_id = a.activity_id
and a.group_id is null
group by reg_state
"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<tr><td align=left>$reg_state<td align=right><a href=\"order-history-one-state.tcl?[export_url_vars reg_state]\">$n_orders</a></tr>\n"
}


ns_write "
</table>

[ad_footer]
"




