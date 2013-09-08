# events/admin/index.tcl
# Owner: bryanche@arsdigita.com

ad_page_contract {
    Displays all upcoming events and the breakdown of registrations
    for them.  Offers various admin options, such as looking at
    registration stats or available venues/activities.  New event
    creation, and checking out/editing events not currently available to
    the public, must be done through subsidiary pages.  
    @param orderby for ad_table
    This is the index page for events administration
    @author Bryan Che (bryanche@arsdigita.com
    @cvs-id index.tcl,v 3.19.2.5 2000/09/22 01:37:37 kevin Exp
} {
    {orderby "start_time"}
}

proc count_link {reg_state n event_id} {
    set history_type "event"
    set state_filter $reg_state

    if {$n > 0} {
	return "
          <a href=\"order-history-one?[export_url_vars history_type event_id state_filter]\">
          $n</a>\n"    
    } else {
	return "$n"
    }
}


set admin_id [ad_maybe_redirect_for_registration]

# Return everything above the bar.  This page can take a while to load. 
append whole_page "[ad_header "[ad_system_name] Events Administration"]
"

# collect the rest of the page



append whole_page "
<h2>Events Administration</h2>
[ad_context_bar_ws [list Events Administration]]
<hr>

<ul>
 <li><a href=\"activities\">View/Add/Edit Activities</a>
 <li><a href=\"venues\">View/Add/Edit Venues</a>
 <li><a href=\"order-history\">Order History</a>
 <li><a href=\"spam-selected-events\">Spam Event Registrants</a>
<p>
<li>(Note: To add/edit an event, you must first go to the 
<a href=\"activities\">activities</a> page to select the type of
activity for your event.  Then, you may add/edit an event
based upon that activity.)
</ul>

<h3>Current Events Registration Status</h3>
"
#the columns for ad_table
set col [list short_name city start_time end_time n_shipped n_pending n_waiting n_all]

#the table definition for ad_table
set table_def {
    {short_name "Activity" {} {<td><a href=\"event.tcl?[export_url_vars event_id]\">$short_name</a></td>}}
    {city "Location" {} {<td>$city, $big_location</td>}}
    {start_time "Start" {} {<td>[util_AnsiDatetoPrettyDate $start_time]</td>}}
    {end_time "End" {} {<td>[util_AnsiDatetoPrettyDate $end_time]</td>}}
    {n_shipped "Confirmed" {} {<td align=center>[count_link "shipped" $n_shipped $event_id]</td>}}
    {n_pending "Pending" {} {<td align=center>[count_link "pending" $n_pending $event_id]</td>}}
    {n_waiting "Wait-Listed" {} {<td align=center>[count_link "waiting" $n_waiting $event_id]</td>}}
    {n_all "<i>Total</i>" {} {<td align=center>[count_link "not_canceled" $n_all $event_id]</td>}}
}

## The counting here works now.
#set selection [ns_db select $db "select 
set sql "select
        e.event_id, e.start_time, e.end_time,
        a.short_name,
        v.city, 
        decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location,
	count(distinct r.reg_id) as n_shipped,
	count (distinct pending_orders.reg_id) as n_pending,
	count (distinct waiting_orders.reg_id) as n_waiting,
	count(distinct r.reg_id) + count(distinct pending_orders.reg_id) + count(distinct waiting_orders.reg_id) as n_all
   from events_events e, events_activities a, events_reg_shipped r,
        events_venues v, events_prices p, country_codes cc,
        (select reg_id, price_id from events_registrations
          where reg_state = 'pending') pending_orders,
        (select reg_id, price_id from events_registrations
          where reg_state = 'waiting') waiting_orders
  where e.end_time +3 > sysdate
    and cc.iso = v.iso
    and e.activity_id = a.activity_id
    and v.venue_id = e.venue_id
    and e.available_p = 't'
    and p.event_id = e.event_id
    and p.price_id = r.price_id(+)
    and p.price_id = pending_orders.price_id(+)
    and p.price_id = waiting_orders.price_id(+)
    and a.group_id in (select distinct group_id
		   from user_group_map
		   where user_id = :admin_id)
    group by e.event_id, city, start_time, end_time, short_name,
           v.iso, v.usps_abbrev, cc.country_name
union
 select 
        e.event_id, e.start_time, e.end_time,
        a.short_name,
        v.city, 
        decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location,
	count(distinct r.reg_id) as n_shipped,
	count (distinct pending_orders.reg_id) as n_pending,
	count (distinct waiting_orders.reg_id) as n_waiting,
	count(distinct r.reg_id) + count(distinct pending_orders.reg_id) + count(distinct waiting_orders.reg_id) as n_all
   from events_events e, events_activities a, events_reg_shipped r,
        events_venues v, events_prices p, country_codes cc,
        (select reg_id, price_id from events_registrations
         where reg_state = 'pending') pending_orders,
        (select reg_id, price_id from events_registrations
         where reg_state = 'waiting') waiting_orders
  where e.end_time +3 > sysdate
    and cc.iso = v.iso
    and e.activity_id = a.activity_id
    and v.venue_id = e.venue_id
    and e.available_p = 't'
    and a.group_id is null
    and p.event_id = e.event_id
    and p.price_id = r.price_id(+)
    and p.price_id = pending_orders.price_id(+)
    and p.price_id = waiting_orders.price_id(+)
  group by e.event_id, city, start_time, end_time, short_name,
           v.iso, v.usps_abbrev, cc.country_name
  [ad_order_by_from_sort_spec $orderby $table_def]
"

set bind_vars [ad_tcl_vars_to_ns_set admin_id]

append whole_page "
<p>
[ad_table -bind $bind_vars -Tcolumns $col -Tmissing_text "<em>There are no current events to display</em>" -Torderby $orderby current_events_table $sql $table_def]
[ad_footer]
"


db_release_unused_handles

# Headers and context bar already returned
doc_return  200 text/html $whole_page

##### File Over
