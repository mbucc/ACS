# File:  events/admin/order-history-ug.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Displays order history grouped by user group. 
#####

ad_page_contract {
    Displays order history grouped by user group. 

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-history-ug.tcl,v 3.8.6.5 2000/09/22 01:37:38 kevin Exp
} {
}

set user_id [ad_maybe_redirect_for_registration]

# prepare the page to be returned
set whole_page ""

append whole_page "[ad_header "[ad_system_name] Events Administration: Order History - By User Group"]

<h2>Order History - By User Group</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By User Group"]
<hr>

<table border=2 cellpadding=5>
<tr>
 <th>User Group
 <th>Orders
"

set history_type "group"

#create a bunch of views to do this select...
db_foreach sel_regs "
 select group_name, um.group_id, sum(distinct group_orders) as n_orders
   from user_groups ug, user_group_map um,
       (select group_id, sum(ev_num) as group_orders 
          from events_activities a,
              (select activity_id, sum(num) as ev_num 
                 from events_events e,
                     (select p.event_id, count(1) as num 
                        from events_registrations r, events_prices p
                       where p.price_id = r.price_id group by p.event_id
                     ) order_count
                where e.event_id = order_count.event_id(+)
                group by activity_id
              ) ev_count
         where a.activity_id = ev_count.activity_id(+)
         group by group_id
       ) group_count
  where ug.group_id = group_count.group_id(+)
    and um.user_id = :user_id
    and ug.group_id = um.group_id
  group by group_name, um.group_id
  order by group_name
" {
    if {[empty_string_p $n_orders]} {
	append whole_page "<tr>
	<td>$group_name
	<td>0"
    } else {
	append whole_page "<tr>
	<td>$group_name
	<td><a href=\"order-history-one?[export_url_vars group_id history_type]\">$n_orders</a>\n"
    }
}

db_1row sel_no_group "
 select decode(sum(group_orders), null, 0, sum(group_orders)) as n_orders
   from (select group_id, sum(ev_num) as group_orders 
           from events_activities a,
               (select activity_id, sum(num) as ev_num 
                  from events_events e,
                      (select p.event_id, count(1) as num 
                         from events_registrations r, events_prices p
                        where p.price_id = r.price_id
                        group by event_id
                      ) order_count
                 where e.event_id = order_count.event_id(+)
                 group by activity_id
               ) ev_count
          where a.activity_id = ev_count.activity_id(+)
          group by group_id
        ) group_count
  where group_count.group_id is null
"

append whole_page "
<tr>
 <td><i>No group</i>
"
if {$n_orders > 0 } {
    append whole_page "
    <td><a href=\"order-history-one?[export_url_vars history_type]\">$n_orders</a>\n"
} else {
    append whole_page "<td> 0 "
}

## clean up, return page

append whole_page "</table>\n [ad_footer]"


doc_return  200 text/html $whole_page

#####
