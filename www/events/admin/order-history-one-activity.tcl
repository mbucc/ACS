set_the_usual_form_variables
#activity_id

ReturnHeaders

ns_write "[ad_header "[ad_system_name] Events Administration: Order History - By Activity"]"

set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

set short_name [database_to_tcl_string $db "select short_name from events_activities where activity_id=$activity_id"]

ns_write "
<h2>Order History - For Activity # $activity_id ($short_name)</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] [list "order-history-activity.tcl" "By Activity"] "Activity"]

<hr>

<table border cellpadding=5>
<tr>
 <th>Event Location
 <th>Date
 <th>Number of Registrations
"

set selection [ns_db select $db "select 
e.event_id, e.start_time, v.city, v.usps_abbrev, v.iso, 
count(r.reg_id) as n_reg 
from events_activities a, events_events e, events_registrations r,
events_venues v, events_prices p
where e.activity_id = a.activity_id
and a.activity_id = $activity_id
and p.event_id = e.event_id
and p.price_id = r.price_id(+)
and v.venue_id = e.venue_id
group by e.event_id, e.start_time, v.city, v.usps_abbrev, v.iso
order by e.start_time desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<tr>
    <td><a href=\"order-history-one-event.tcl?event_id=$event_id\">
    [events_pretty_location $db_sub $city $usps_abbrev $iso]</a>
    <td>[util_AnsiDatetoPrettyDate $start_time]
    <td>$n_reg registrations"
}
  
ns_write "
</table>

[ad_footer]
"




