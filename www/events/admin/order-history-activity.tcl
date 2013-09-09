# File:  events/admin/order-history-activity.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Display order history grouped by activity
#####
ad_page_contract {
    Display order history grouped by activity

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-history-activity.tcl,v 3.6.6.4 2000/09/22 01:37:37 kevin Exp
} {
}


set admin_id [ad_maybe_redirect_for_registration]

set whole_page ""

append whole_page "[ad_header "[ad_system_name] Events Administration: Order History - By Activity"]

<h2>Order History - By Activity</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Activity"]
<hr>

<table border=2 cellpadding=5>
<tr>
<th align=center>Activity #
<th align=center>Name
<th align=center>Registrations
"



# count the number of orders (in events_registrations) for each activity_id in 
# events_activities

db_foreach sel_activities "select 
      a.short_name, a.activity_id, count(r.reg_id) as n_reg
 from events_activities a, events_registrations r, events_events e,
      events_prices p
 where p.event_id = e.event_id
   and p.price_id = r.price_id(+)
   and a.activity_id = e.activity_id
   and a.group_id in (select distinct group_id
		   from user_group_map
		   where user_id = :admin_id)
 group by a.activity_id, a.short_name
union
 select a.short_name, a.activity_id, count(r.reg_id) as n_reg
   from events_activities a, events_registrations r, events_events e,
        events_prices p
  where p.event_id = e.event_id
    and p.price_id = r.price_id(+)
    and a.activity_id = e.activity_id
    and a.group_id is null
  group by a.activity_id, a.short_name
  order by activity_id
" {
    append whole_page "
    <tr>
     <td align=left>$activity_id
     <td align=center>$short_name
    "
    if {$n_reg > 0} {
	append whole_page "
	<td align=right><a href=\"order-history-one-activity?activity_id=$activity_id\">$n_reg</a></tr>\n"
    } else {
	append whole_page "<td align=right>$n_reg"
    }
}
## clean up, return page.
append whole_page "</table>\n [ad_footer] "



doc_return  200 text/html $whole_page

##### EOF
