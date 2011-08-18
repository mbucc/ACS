set admin_id [ad_maybe_redirect_for_registration]

ReturnHeaders

ns_write "[ad_header "[ad_system_name] Events Administration: Order History - By Month"]

<h2>Order History - By Month</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Month"]

<hr>
<table border=2 cellpadding=5>
<tr>
<th align=center>Month
<th align=center>Orders
"

set db [ns_db gethandle]
set selection [ns_db select $db "
select 
to_char(reg_date,'YYYY') as reg_year, 
to_char(reg_date,'Month') as reg_month, 
to_char(reg_date,'MM') as reg_month_number, 
count(reg_id) as n_orders
from events_registrations r, events_events e,
events_prices p
where p.event_id = e.event_id
and p.price_id = r.price_id
and r.reg_id not in 
    (select distinct r.reg_id
    from events_registrations r,events_activities a, events_events e,
    events_prices p
    where
    p.event_id = e.event_id
    and e.activity_id = a.activity_id
    and p.price_id = r.price_id
    and a.group_id not in
     (select group_id from user_group_map
      where user_id != $admin_id)
)
group by to_char(reg_date,'YYYY'), 
to_char(reg_date,'Month'), to_char(reg_date,'MM')
order by reg_year,reg_month
"]

# count the number of orders (in events_registrations) for each date in 
# events_registrations
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    ns_write "<tr>
    <td align=left>$reg_month $reg_year
    <td align=right><a href=\"order-history-date.tcl?reg_month=[ns_urlencode $reg_month]&reg_year=[ns_urlencode $reg_year]\">$n_orders</a></tr>\n"
}

ns_write "
</table>

[ad_footer]
"




