# File:  events/admin/order-history-state.tcl
# Owner: bryanche@arsdigita.com
# Purpose:   ...
#####
ad_page_contract {
    Lists number of registrations in each state.

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-history-state.tcl,v 3.9.2.4 2000/09/22 01:37:38 kevin Exp
} {
}

set admin_id [ad_maybe_redirect_for_registration]

append whole_page "[ad_header "[ad_system_name] Events Administration: Order History - By Order State"]

<h2>Order History - By Registration State</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Registration State"]

<hr>

<table border=2 cellpadding=5>
<tr>
<th align=center>Registration State
<th align=center>Registrations
"



# count the number of orders (in events_registrations) for each order_state in 
# events_registrations

set history_type "state"

db_foreach sel_regs "
select 
reg_state, count(reg_id) as n_orders
from events_registrations r, events_activities a, events_events e,
events_prices p
where p.event_id = e.event_id
and p.price_id = r.price_id
and e.activity_id = a.activity_id
     and r.reg_id not in (select distinct r.reg_id
          from events_registrations r,events_activities a, events_events e,
               events_prices p
         where p.event_id = e.event_id
           and e.activity_id = a.activity_id
           and p.price_id = r.price_id
           and a.group_id not in (select distinct group_id 
                from user_group_map 
               where user_id = :admin_id) )
group by reg_state
order by reg_state
" {
    #set r_state $reg_state
    set state_filter $reg_state

    append whole_page "<tr><td align=left>$reg_state<td align=right><a href=\"order-history-one?[export_url_vars state_filter]\">$n_orders</a></tr>\n"
}

append whole_page " </table>\n [ad_footer] "


doc_return  200 text/html $whole_page
#####
