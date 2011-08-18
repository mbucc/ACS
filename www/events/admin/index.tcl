set admin_id [ad_maybe_redirect_for_registration]


ReturnHeaders

ns_write "[ad_header "[ad_system_name] Events Administration"]"

set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]


#this is for stuffing into the spam module
set sql_post_select "from users, events_reg_shipped r
where users.user_id = r.user_id
"

ns_write "
<h2>Events Administration</h2>
[ad_context_bar_ws "Events Administration"]


<hr>
<ul>
<li><a href=\"activities.tcl\">View/Add/Edit Activities</a>
<li><a href=\"venues.tcl\">View/Add/Edit Venues</a>
<li><a href=\"order-history.tcl\">Order History</a>
<li><a href=\"spam/action-choose.tcl?[export_url_vars sql_post_select]\">Spam Everyone</a>
<li><a href=\"spam-selected-events.tcl\">Spam Selected Events</a>
</ul>

<h3>Current Events Registration Status</h3>
<table cellpadding=5>
<blockquote><table cellpadding=5>
<tr>
 <th>Event
 <th>Confirmed 
 <th>Pending 
 <th>Wait-Listed
</tr>
"

set selection [ns_db select $db "select e.event_id, v.city, 
e.start_time, count(r.reg_id) as n_orders,
count (pending_orders.reg_id) as n_pending,
count (waiting_orders.reg_id) as n_waiting
from events_events e, events_activities a, events_reg_shipped r,
events_venues v, events_prices p,
(select reg_id, price_id 
 from events_registrations
 where reg_state = 'pending') pending_orders,
(select reg_id, price_id 
 from events_registrations
 where reg_state = 'waiting') waiting_orders
where e.start_time > sysdate
and e.activity_id = a.activity_id
and v.venue_id = e.venue_id
and e.available_p = 't'
and p.event_id = e.event_id
and p.price_id = r.price_id(+)
and p.price_id = pending_orders.price_id(+)
and p.price_id = waiting_orders.price_id(+)
and a.group_id in (select distinct group_id
		   from user_group_map
		   where user_id = $admin_id)
group by e.event_id, city, start_time
union
select e.event_id, v.city, 
e.start_time, count(r.reg_id) as n_orders,
count (pending_orders.reg_id) as n_pending,
count (waiting_orders.reg_id) as n_waiting
from events_events e, events_activities a, events_reg_shipped r,
events_venues v, events_prices p,
(select reg_id, price_id 
 from events_registrations
 where reg_state = 'pending') pending_orders,
(select reg_id, price_id 
 from events_registrations
 where reg_state = 'waiting') waiting_orders
where e.start_time > sysdate
and e.activity_id = a.activity_id
and v.venue_id = e.venue_id
and e.available_p = 't'
and a.group_id is null
and p.event_id = e.event_id
and p.price_id = r.price_id(+)
and p.price_id = pending_orders.price_id(+)
and p.price_id = waiting_orders.price_id(+)
group by e.event_id, city, start_time
order by start_time

"]

#    <td><a href=\"event.tcl?[export_url_vars event_id]\">
#    $city, [util_AnsiDatetoPrettyDate $start_time]</a>\n
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set event [events_pretty_event $db_sub $event_id]
    regsub -all " from " $event "<br>from " event
    ns_write "
    <tr>\n
    <td><a href=\"event.tcl?event_id=$event_id\">$event</a>
    <td><a href=\"order-history-one-event.tcl?[export_url_vars event_id]\">
    $n_orders</a>\n
    "
    if {$n_pending > 0} {
	ns_write "    
	<td><a href=\"reg-pending.tcl?[export_url_vars event_id]\">
	$n_pending</a>\n"
    } else {
	ns_write "
	<td>$n_pending\n"
    }

    if {$n_waiting > 0} {
	ns_write "    
	<td><a href=\"reg-waiting.tcl?[export_url_vars event_id]\">
	$n_waiting</a>\n"
    } else {
	ns_write "
	<td>$n_waiting\n"
    }
}

ns_write "</table></blockquote>"


ns_write "[ad_footer]"
