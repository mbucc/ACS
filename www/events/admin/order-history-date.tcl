set admin_id [ad_maybe_redirect_for_registration]

set_form_variables 0

# optional reg_year and reg_month

if [info exists reg_year] {
    # assume that we got a month also
    set page_title "Orders in $reg_month $reg_year"
    set where_clause "
where to_char(reg_date,'Month') = '$reg_month' 
and to_char(reg_date,'YYYY') = '$reg_year'
and "
} else {
    set page_title "Orders by Date"
    set where_clause "where"
}

ReturnHeaders

ns_write "[ad_header $page_title]

<h2>$page_title</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Date"]

<hr>

<table border=2 cellpadding=5>
<tr>
<th align=center>Date
<th align=center>Orders
"

#set db [ns_db gethandle]
set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]



# count the number of orders (in events_registrations) for each date in 
# events_registrations


set selection [ns_db select $db "
select 
trunc(reg_date) as reg_date, 
count(reg_id) as n_orders
from events_registrations r, events_events e,
events_prices p
$where_clause
p.event_id = e.event_id
and p.price_id = r.price_id
and r.reg_id not in 
    (select distinct r.reg_id
    from events_registrations r,events_activities a, events_events e,
    events_prices p
    $where_clause
    p.event_id = e.event_id
    and e.activity_id = a.activity_id
    and p.price_id = r.price_id
    and a.group_id not in
     (select group_id from user_group_map
      where user_id != $admin_id)
)
group by trunc(reg_date)
order by reg_date desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    ns_write "<tr>
    <td align=left>[util_IllustraDatetoPrettyDate $reg_date]
    <td align=right><a href=\"order-history-one-date.tcl?reg_date=[ns_urlencode $reg_date]\">$n_orders</a>\n"
   
}


ns_write "
</table>

[ad_footer]
"




