set admin_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables

# id_query, name_query

if { [info exists id_query] && [string compare $id_query ""] != 0 } {
    ad_returnredirect "reg-view.tcl?reg_id=$id_query"
    return
} elseif { ![info exists name_query] || [string compare $name_query ""] == 0 } {
    ad_return_error "Please enter search info"  "Please enter either an order # or the customer's last name"
    return
} 
  
ReturnHeaders
ns_write "[ad_header "Orders with Last Name Containing \"$name_query\""]

<h2>Orders with Last Name Containing \"$name_query\"</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "Search"]

<hr>
<ul>

"
set db [ns_db gethandle]

set selection [ns_db select $db "select 
u.first_names, u.last_name, 
r.reg_id, r.reg_state, 
a.short_name, v.city, v.usps_abbrev, v.iso
from events_registrations r, events_activities a, events_events e,
events_prices p, events_venues v, users u,
user_groups ug, user_group_map ugm
where p.event_id = e.event_id
and e.activity_id = a.activity_id
and v.venue_id = e.venue_id
and u.user_id = r.user_id
and upper(u.last_name) like upper('%$QQname_query%')
and a.group_id = ugm.group_id
and ugm.group_id = ug.group_id
and ugm.user_id = $admin_id
and p.price_id = r.price_id
union
select 
u.first_names, u.last_name, 
r.reg_id, r.reg_state, 
a.short_name, v.city, v.usps_abbrev, v.iso
from events_registrations r, events_activities a, events_events e,
events_prices p, events_venues v, users u
where p.event_id = e.event_id
and e.activity_id = a.activity_id
and v.venue_id = e.venue_id
and u.user_id = r.user_id
and upper(u.last_name) like upper('%$QQname_query%')
and a.group_id is null
order by reg_id"]
    set n_rows_found 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	incr n_rows_found
	ns_write "<li>"
	events_write_order_summary
    }
    if { $n_rows_found == 0 } {
	ns_write "no orders found"
    }
    ns_write "</ul>
    
[ad_footer]
"


