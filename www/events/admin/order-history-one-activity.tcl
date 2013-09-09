# File:  events/admin/order-history-one-activity.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  To provide an overview of order history grouped by activity.
#####

ad_page_contract {
    Purpose:  To provide an overview of order history grouped by activity.

    @param activity_id the activity whose history we are viewing

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-history-one-activity.tcl,v 3.7.6.4 2000/09/22 01:37:37 kevin Exp
} {
    {activity_id:integer,notnull}
}

set whole_page ""

append whole_page "[ad_header "[ad_system_name] Events Administration: Order History - By Activity"]"



set short_name [db_string sel_name "select short_name from events_activities where activity_id=$activity_id"]

append whole_page "
  <h2>Order History - For Activity # $activity_id ($short_name)</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] [list "order-history-activity.tcl" "By Activity"] "Activity"]
<hr>

<table border cellpadding=5>
<tr>
 <th>Event Location
 <th>Date
 <th>Number of Registrations
"

set history_type "event"

db_foreach sel_reg "select 
      e.event_id, e.start_time, v.city, 
      decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location,
      count(r.reg_id) as n_reg 
 from events_activities a, events_events e, events_registrations r,
      events_venues v, events_prices p, country_codes cc
where e.activity_id = a.activity_id
  and a.activity_id = :activity_id
  and p.event_id = e.event_id
  and p.price_id = r.price_id(+)
  and v.venue_id = e.venue_id
  and cc.iso = v.iso
group by e.event_id, e.start_time, v.city, v.usps_abbrev, v.iso, cc.country_name
order by e.start_time desc
" {
    append whole_page "<tr>
     <td><a href=\"order-history-one?[export_url_vars event_id history_type]\">$city, $big_location</a>
     <td>[util_AnsiDatetoPrettyDate $start_time]
     <td>$n_reg registrations"
}
  
## clean up, return page

append whole_page " </table>\n [ad_footer] "



doc_return  200 text/html $whole_page

##### File Over
