set user_id [ad_maybe_redirect_for_registration]
ReturnHeaders

ns_write "[ad_header "[ad_system_name] Events Administration: Order History - By User Group"]

<h2>Order History - By User Group</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By User Group"]

<hr>
<table border=2 cellpadding=5>
<tr>
 <th>User Group
 <th>Orders
"

set db [ns_db gethandle]

#create a bunch of views to do this select...
set selection [ns_db select $db "select 
group_name, um.group_id, sum(group_orders) as n_orders
from user_groups ug, user_group_map um,
 (select group_id, sum(ev_num) as group_orders from events_activities a,
  (select activity_id, sum(num) as ev_num from events_events e,
   (select p.event_id, count(1) as num 
    from events_registrations r, events_prices p
    where p.price_id = r.price_id
    group by event_id
   ) order_count
   where e.event_id = order_count.event_id(+)
   group by activity_id
  ) ev_count
 where a.activity_id = ev_count.activity_id(+)
 group by group_id
 ) group_count
where ug.group_id = group_count.group_id(+)
and um.user_id = $user_id
and ug.group_id = um.group_id
group by group_name, um.group_id
order by group_name
"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if {[empty_string_p $n_orders]} {
	ns_write "<tr>
	<td>$group_name
	<td>0"
    } else {
	ns_write "<tr>
	<td>$group_name
	<td><a href=\"order-history-one-ug.tcl?[export_url_vars group_id]\">$n_orders</a>\n"
    }
}

set selection [ns_db 1row $db "select 
decode(sum(group_orders), null, 0, sum(group_orders)) as n_orders
from 
 (select group_id, sum(ev_num) as group_orders from events_activities a,
  (select activity_id, sum(num) as ev_num from events_events e,
   (select p.event_id, count(1) as num 
    from events_registrations r, events_prices p
    where p.price_id = r.price_id
    group by event_id
   ) order_count
   where e.event_id = order_count.event_id(+)
   group by activity_id
  ) ev_count
 where a.activity_id = ev_count.activity_id(+)
 group by group_id
 ) group_count
where group_count.group_id is null"]

set_variables_after_query
ns_write "<tr>
<td><i>No group</i>
"
if {$n_orders > 0 } {
    ns_write "
    <td><a href=\"order-history-one-ug.tcl\">$n_orders</a>\n"
} else {
    ns_write "<td>0"
}

ns_write "</table>[ad_footer]"