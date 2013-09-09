# File:  events/admin/order-history-date.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Displays order-history grouped by date.
#####

ad_page_contract {
    Displays order-history grouped by date.

    @param year optional arg for what year to view
    @param month optional arg for what month to view

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-history-date.tcl,v 3.10.2.5 2000/09/22 01:37:37 kevin Exp
} {
    {year:optional}
    {month:optional}
}

set admin_id [ad_maybe_redirect_for_registration]

if {[info exists year] && [info exists month]} {
    set page_title "Orders in $month $year"
    set where_clause "
      where to_char(reg_date,'fmMonth') = :month
        and to_char(reg_date,'YYYY') = :year
        and "
} else {
    set page_title "Orders by Date"
    set where_clause "where"
}

# prepare page to be returned
set whole_page ""

append whole_page "[ad_header $page_title]

<h2>$page_title</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Date"]
<hr>

<table border=2 cellpadding=5>
<tr>
  <th align=center>Date
  <th align=center>Orders
"



# count the number of orders (in events_registrations) for each date in 
# events_registrations

set history_type "date"

db_foreach sel_regs "
  select trunc(reg_date) as reg_date, 
         count(reg_id) as n_orders
    from events_registrations r, events_events e, events_prices p
    $where_clause  p.event_id = e.event_id
     and p.price_id = r.price_id
     and r.reg_id not in (select distinct r.reg_id
           from events_registrations r,events_activities a, events_events e,
                events_prices p
           $where_clause p.event_id = e.event_id
            and e.activity_id = a.activity_id
            and p.price_id = r.price_id
            and a.group_id not in (select distinct group_id 
                  from user_group_map 
                 where user_id = :admin_id) )
  group by trunc(reg_date)
  order by reg_date desc
" {
    #can't export reg_date since &reg is a special character
    set r_date $reg_date

    append whole_page "<tr>
     <td align=left>[util_IllustraDatetoPrettyDate $reg_date]
     <td align=right><a href=\"order-history-one?[export_url_vars r_date history_type]\">$n_orders</a>\n"
   
}

### clean up, return page.
append whole_page " </table>\n [ad_footer] "



doc_return  200 text/html $whole_page
##### File Over. 

