set_the_usual_form_variables 0
#maybe group_id

set db [ns_db gethandle]

ReturnHeaders

if {[exists_and_not_null group_id]} {
    set group_name [database_to_tcl_string $db "select group_name
    from user_groups
    where group_id = $group_id"]
} else {
    set group_name "<i>No Group</i>"
}

ns_write "[ad_header "Orders for $group_name"]

<h2>Orders for $group_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] [list "order-history-ug.tcl" "User Groups"] "User Group"]
<hr>

<ul>
"


if {[exists_and_not_null group_id]} {
    set selection [ns_db select $db "select 
    r.reg_id, r.reg_state, 
    u.first_names, u.last_name, a.short_name
    from events_registrations r, events_activities a, events_events e, users u,
    events_prices p
    where a.group_id = $group_id
    and e.activity_id = a.activity_id
    and p.event_id = e.event_id
    and p.price_id = r.price_id
    and u.user_id = r.user_id
    order by reg_id desc"]
} else {
    set selection [ns_db select $db "select 
    r.reg_id, r.reg_state, 
    u.first_names, u.last_name, a.short_name
    from events_registrations r, events_activities a, events_events e, users u,
    events_prices p
    where a.group_id is null
    and e.activity_id = a.activity_id
    and p.event_id = e.event_id
    and p.price_id = r.price_id
    and u.user_id = r.user_id
    order by reg_id desc"]
}

set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "\n<li>"
    events_write_order_summary
    incr counter
}

if {$counter == 0} {
    ns_write "<li>No orders found"
}
  
ns_write "
</ul>

[ad_footer]
"


