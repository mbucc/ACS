set admin_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables

# event_id, maybe order_by

set db [ns_db gethandle]

set selection [ns_db 1row $db "select 
a.short_name, a.activity_id,
v.city, v.usps_abbrev, v.iso,
to_char(e.start_time, 'YYYY-MM-DD') as start_date, 
to_char(e.start_time, 'HH:MI AM') as start_pretty_time
from events_events e, events_activities a, events_venues v
where e.activity_id = a.activity_id
and e.event_id = $event_id
and v.venue_id = e.venue_id
"]
set_variables_after_query

ReturnHeaders


ns_write "
<h2>Order History - For Event # $event_id ($short_name)</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] [list "order-history-activity.tcl" "By Activity"] [list "order-history-one-activity.tcl?[export_url_vars activity_id]" "Activity"] "Event"]


<hr>
[events_pretty_location $db $city $usps_abbrev $iso]
on [util_AnsiDatetoPrettyDate $start_date] at $start_pretty_time
<p>
"

if { [info exists order_by] && $order_by == "name" } {
    set order_by_clause "last_name, first_names"
    set option "<a href=\"order-history-one-event.tcl?event_id=$event_id&order_by=reg_id\">sort by time of order</a>"
} else {
    set order_by_clause "reg_id desc"
    set option "<a href=\"order-history-one-event.tcl?event_id=$event_id&order_by=name\">sort by last name</a>"
}

ns_write "

$option

<ul>
"

set selection [ns_db select $db "select 
r.reg_id, r.reg_state,
u.first_names || ' ' || u.last_name as user_name, u.last_name, u.first_names,
u.email, r.reg_date,
r.org, r.title_at_org, r.where_heard
from events_registrations r, users u,
events_activities a, events_events e, events_prices p,
user_group_map ugm
where p.event_id = $event_id
and p.price_id = r.price_id
and u.user_id = r.user_id
and e.activity_id = a.activity_id
and a.group_id = ugm.group_id
and ugm.user_id = $admin_id
union
select 
r.reg_id, r.reg_state,
u.first_names || ' ' || u.last_name as user_name, u.last_name, u.first_names,
u.email, r.reg_date,
r.org, r.title_at_org, r.where_heard
from events_registrations r, users u,
events_activities a, events_events e, events_prices p
where p.event_id = $event_id
and p.price_id = r.price_id
and u.user_id = r.user_id
and e.activity_id = a.activity_id
and a.group_id is null
order by $order_by_clause
"]

set counter 0
set registrants ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if {$reg_state == "canceled"} {
	set canceled_text " <font color=red>(canceled)</font>"
    } else {
	set canceled_text ""
    }

    incr counter
    # we don't use events_write_order_summary because it would repeat too
    # much info from the above title
    append registrants "<li><a href=\"reg-view.tcl?reg_id=$reg_id\">$reg_id</a> from $user_name ($email) on $reg_date\n"

    if ![empty_string_p $org] {
	append registrants ", from $org"
    } 

    if ![empty_string_p $title_at_org] {
	append registrants " ($title_at_org)"
    }

    append registrants "$canceled_text"

#    if ![empty_string_p $attending_reason] {
#	append registrants "<blockquote><b>reason:</b> $attending_reason</blockquote>"
#    }

    if ![empty_string_p $where_heard] {
	append registrants "<blockquote><b>where heard:</b> $where_heard</blockquote>"
    }
}
  
if { $counter == 0 } {
    ns_write "no orders found"
} else {
    ns_write $registrants
}

ns_write "
</ul>

[ad_footer]
"




