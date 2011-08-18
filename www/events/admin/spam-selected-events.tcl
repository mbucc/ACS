set admin_id [ad_maybe_redirect_for_registration]

ReturnHeaders


ns_write "[ad_header "Spam Event"]"

set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]


ns_write "
<h2>Spam Event</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Spam Event"]

<hr>
Select the event you would like to spam:
<ul>
"

set selection [ns_db select $db "select
a.short_name,
e.start_time, e.event_id,
v.city, v.usps_abbrev, v.iso
from events_activities a, events_events e, events_venues v,
user_groups ug, user_group_map ugm
where a.activity_id = e.activity_id
and v.venue_id = e.venue_id
and a.group_id = ugm.group_id
and ugm.group_id = ug.group_id
and ugm.user_id = $admin_id
union
select
a.short_name,
e.start_time, e.event_id,
v.city, v.usps_abbrev, v.iso
from events_activities a, events_events e, events_venues v
where a.activity_id = e.activity_id
and v.venue_id = e.venue_id
and a.group_id is null
order by short_name, start_time
"]

set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    set sql_post_select "from users, events_reg_shipped r, events_prices p
    where p.event_id = $event_id
    and users.user_id = r.user_id
    and p.price_id = r.price_id
    "

    ns_write "<li>
    <a href=\"spam-selected-event.tcl?[export_url_vars event_id]\">$short_name:
    [events_pretty_location $db_sub $city $usps_abbrev $iso]
    on [util_AnsiDatetoPrettyDate $start_time] </a>"
    
    incr counter
}

if {$counter == 0} {
    ns_write "<li>There are no events in the system"
}

ns_write "</ul>[ad_footer]"