# File:  events/admin/order-same-person.tcl
# Owner: bryanche@arsdigita.com
# Purpose: ...
#####


ad_page_contract {
    Lists registrations by one user

    @param user_id the user whose registrations we're listing

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-same-person.tcl,v 3.5.2.4 2000/09/22 01:37:38 kevin Exp
} {
    {user_id:integer,notnull}
}

set admin_id [ad_maybe_redirect_for_registration]

set output_html_page "whole_page"
# this is for events_write_order_summary

set whole_page ""


db_1row sel_names "
 select first_names, last_name from users
  where user_id = :user_id"

append whole_page "
   [ad_header "Orders by $first_names $last_name"]
<h2>Orders by $first_names $last_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Order History"]
<hr>

<ul>
"

db_foreach sel_regs " 
 select r.reg_id, r.reg_state, a.short_name, r.reg_date
   from events_registrations r, events_activities a, events_events e,
        user_groups ug, user_group_map ugm, events_prices p
  where p.event_id = e.event_id
    and r.price_id = p.price_id
    and e.activity_id = a.activity_id
    and r.user_id = :user_id
    and a.group_id = ugm.group_id
    and ugm.group_id = ug.group_id
    and ugm.user_id = :admin_id
union
 select r.reg_id, r.reg_state, a.short_name, r.reg_date
   from events_registrations r, events_activities a, events_events e,
        user_groups ug, user_group_map ugm, events_prices p
  where p.event_id = e.event_id
    and r.price_id = p.price_id
    and e.activity_id = a.activity_id
    and r.user_id = :user_id
    and a.group_id is null
  order by reg_id desc" {
    append whole_page "\n<li>"
    events_write_order_summary
}

## clean up, return page.

append whole_page " </ul>\n [ad_footer] "


doc_return  200 text/html $whole_page

##### File Over 
