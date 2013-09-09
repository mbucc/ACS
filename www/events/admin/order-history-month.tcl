# File:  events/admin/order-history-month.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Provides an overview of order history grouped by month.
#####

ad_page_contract {
    Purpose:  Provides an overview of order history grouped by month.

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-history-month.tcl,v 3.7.6.5 2000/09/22 01:37:37 kevin Exp
} {
}

set admin_id [ad_maybe_redirect_for_registration]

# prepare page to be returned
set whole_page ""
append whole_page "
  [ad_header "[ad_system_name] Events Administration: Order History - By Month"]
<h2>Order History - By Month</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Month"]
<hr>

<table border=2 cellpadding=5>
<tr>
<th align=center>Month
<th align=center>Orders
"


# count the number of orders (in events_registrations) for each date in 
# events_registrations
db_foreach sel_reg "
  select to_char(reg_date,'YYYY') as year, 
         to_char(reg_date,'fmMonth') as month, 
         to_char(reg_date,'MM') as month_number, 
         count(reg_id) as n_orders
    from events_registrations r, events_events e, events_prices p
   where p.event_id = e.event_id
     and p.price_id = r.price_id
     and r.reg_id not in (select distinct r.reg_id
          from events_registrations r,events_activities a, events_events e,
               events_prices p
         where p.event_id = e.event_id
           and e.activity_id = a.activity_id
           and p.price_id = r.price_id
           and a.group_id not in (select distinct group_id 
                from user_group_map 
               where user_id = :admin_id) )
group by to_char(reg_date,'YYYY'), 
         to_char(reg_date,'fmMonth'), 
         to_char(reg_date,'MM')
order by year,month
" {
    append whole_page "<tr>
    <td align=left>$month $year
    <td align=right><a href=\"order-history-date?[export_url_vars month year]\">$n_orders</a></tr>\n"
}

## clean up, return page

append whole_page " </table>\n [ad_footer] "


doc_return  200 text/html $whole_page

##### File Over
