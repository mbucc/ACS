set admin_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables
# urlencoded first_names and last_name
#user_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select
first_names, last_name
from users
where user_id = $user_id"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_header "Orders by $first_names $last_name"]

<h2>Orders by $first_names $last_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Order History"]

<hr>

<ul>
"

set selection [ns_db select $db "select r.reg_id, 
r.reg_state, a.short_name, 
r.reg_date
from events_registrations r, events_activities a, events_events e,
user_groups ug, user_group_map ugm, events_prices p
where p.event_id = e.event_id
and r.price_id = p.price_id
and e.activity_id = a.activity_id
and r.user_id = $user_id
and a.group_id = ugm.group_id
and ugm.group_id = ug.group_id
and ugm.user_id = $admin_id
union
select r.reg_id, 
r.reg_state, a.short_name, 
r.reg_date
from events_registrations r, events_activities a, events_events e,
user_groups ug, user_group_map ugm, events_prices p
where p.event_id = e.event_id
and r.price_id = p.price_id
and e.activity_id = a.activity_id
and r.user_id = $user_id
and a.group_id is null
order by reg_id desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "\n<li>"
    events_write_order_summary
}
  
ns_write "
</ul>

[ad_footer]
"




