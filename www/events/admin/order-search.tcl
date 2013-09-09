# File:  events/admin/order-search.tcl
# Owner: bryanche@arsdigita.com
# Purpose: Full text search of existing orders 
#####

ad_page_contract {
    Search for existing orders

    @param id_query a registration id to search for
    @param name_query a name to search for

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-search.tcl,v 3.9.2.4 2000/09/22 01:37:38 kevin Exp
} {
    {id_query:integer,optional}
    {name_query:trim,optional}
}

set admin_id [ad_maybe_redirect_for_registration]
set output_html_page "whole_page"
# for events_write_order_summary

set whole_page ""

if { [info exists id_query] && [string compare $id_query ""] != 0 } {
    ad_returnredirect "reg-view.tcl?reg_id=$id_query"
    return
} elseif { ![info exists name_query] || [string compare $name_query ""] == 0 } {
    ad_return_warning "Please enter search info"  "Please enter either an order # or the customer's last name"
    return
} 
  
append whole_page "
   [ad_header "Orders with Last Name Containing \"$name_query\""]
<h2>Orders with Last Name Containing \"$name_query\"</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "Search"]
<hr>

<ul>
"

set n_rows_found 0

db_foreach sel_regs "
select u.first_names, u.last_name, r.reg_id, r.reg_state,
a.short_name, v.city, v.usps_abbrev, v.iso
from events_registrations r, events_activities a, events_events e,
events_prices p, events_venues v, users u,
user_group_map ugm
where upper(u.last_name) like upper(:name_query)
and r.user_id = u.user_id
and p.price_id = r.price_id
and e.event_id = p.event_id
and a.activity_id = e.activity_id
and v.venue_id = e.venue_id
and ugm.group_id = a.group_id
and ugm.user_id = :admin_id
union
select u.first_names, u.last_name, r.reg_id, r.reg_state,
a.short_name, v.city, v.usps_abbrev, v.iso
from events_registrations r, events_activities a, events_events e,
events_prices p, events_venues v, users u
where upper(u.last_name) like upper(:name_query)
and r.user_id = u.user_id
and p.price_id = r.price_id
and e.event_id = p.event_id
and a.activity_id = e.activity_id
and v.venue_id = e.venue_id
and a.group_id is null
order by reg_id
" {
   incr n_rows_found
   append whole_page "<li>"
   events_write_order_summary
}

if { $n_rows_found == 0 } {
   append whole_page "no orders found"
}

## clean up, return

append whole_page "</ul>\n [ad_footer] "


doc_return  200 text/html $whole_page

##### EOF
