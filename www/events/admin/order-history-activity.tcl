set admin_id [ad_maybe_redirect_for_registration]

ReturnHeaders

ns_write "[ad_header "[ad_system_name] Events Administration: Order History - By Activity"]

<h2>Order History - By Activity</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Activity"]

<hr>

<table border=2 cellpadding=5>
<tr>
<th align=center>Activity #
<th align=center>Name
<th align=center>Registrations
"

set db [ns_db gethandle]

# count the number of orders (in events_registrations) for each activity_id in 
# events_activities

set selection [ns_db select $db "select 
a.short_name, a.activity_id, 
count(r.reg_id) as n_reg
from events_activities a, events_registrations r, events_events e,
events_prices p
where p.event_id = e.event_id
and p.price_id = r.price_id(+)
and a.activity_id = e.activity_id
and a.group_id in (select distinct group_id
		   from user_group_map
		   where user_id = $admin_id)
group by a.activity_id, a.short_name
union
select 
a.short_name, a.activity_id, 
count(r.reg_id) as n_reg
from events_activities a, events_registrations r, events_events e,
events_prices p
where p.event_id = e.event_id
and p.price_id = r.price_id(+)
and a.activity_id = e.activity_id
and a.group_id is null
group by a.activity_id, a.short_name
order by activity_id
"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "
    <tr>
     <td align=left>$activity_id
     <td align=center>$short_name
    "
    if {$n_reg > 0} {
	ns_write "
	<td align=right><a href=\"order-history-one-activity.tcl?activity_id=$activity_id\">$n_reg</a></tr>\n"
    } else {
	ns_write "<td align=right>$n_reg"
    }
}
ns_write "
</table>

[ad_footer]
"




