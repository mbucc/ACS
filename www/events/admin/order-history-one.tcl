# File:  events/admin/order-history-one.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  A page for displaying order histories by date, event, 
#           user group, or registration state.  
#####

proc color_reg_state {reg_state} {
    if {[string compare $reg_state "canceled"] == 0} {
	return "<font color=red>$reg_state</font>"
    } elseif {[string compare $reg_state "shipped"] == 0} {
	return "<font color=green>$reg_state</font>"
    } else {
	return $reg_state
    }
}

#history_type is (date, event, group, state)
#r_date, event_id, group_id (or no group_id), reg_state
#start_id, order_by (event)
#maybe state_filter
ad_page_contract {
    displays the order history of one date, event, group, or state

    @param history_type date, event, group, or state
    @param r_date the date if history_type =date
    @param event_id the event if history_type=event
    @param group_id the group_id (or no group_id) if history_type=group
    @param reg_state the reg_state if history_type=state
    @param start_id the id at which to start viewing registrations
    @param order_by how to order the registrations (for ad_table)
    @param state_filter what state to show (for ad_dimensional)

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-history-one.tcl,v 3.17.2.6 2000/09/22 01:37:37 kevin Exp
} {
    {history_type ""}
    {r_date:optional}
    {event_id:integer,optional}
    {group_id:integer,optional}
    {reg_state:optional}
    {start_id:optional}
    {orderby "1"}
    {state_filter "all"}
    {range_type "reg_id"}
}

set admin_id [ad_maybe_redirect_for_registration]

if {[string compare $range_type "reg_id"] == 0} {
    #order by reg_id
    set reg_range_order_sql "order by 2 asc"
} else {
    #range_type = "last_name"
    #order by last_name
    set reg_range_order_sql "order by 1 asc"
}


#dimensional filter for which conferences to show
set dimensional {
    {range_type "Group Registration Blocks By:" reg_id {
	{reg_id "Registration Number" {}}
	{last_name "Last Name" {}} }
    }
    {state_filter "Show Registration States:" all {
	{shipped "Shipped" {where "reg_state = 'shipped'"}}
	{canceled "Canceled" {where "reg_state = 'canceled'"}}
	{pending "Pending" {where "reg_state = 'pending'"}}
	{waiting "Waiting" {where "reg_state = 'waiting'"}}
	{not_canceled "Not Canceled" {where "reg_state <> 'canceled'"}}
	{all "All" {}} }   
    }
}

#the columns for ad_table
#set col [list reg_id last_name email title_at_org org short_name reg_state]
set col [list 1 2 3 4 5 6 7]


#the table definition for ad_table
#unfortunately, we have to sort by column index in order for this table
#to work across all queries...
set table_def {
    {1 "Reg. ID" {sort_by_pos} {<td><a href=\"reg-view.tcl?[export_url_vars reg_id]\">$reg_id</a></td>}}
    {2 "Name" {sort_by_pos} {<td>$first_names $last_name</td>}}
    {3 "E-mail" {sort_by_pos} {<td>$email</td>}}
    {4 "Title" {sort_by_pos} {<td>$title_at_org</td>}}
    {5 "Org" {sort_by_pos} {<td>$org</td>}}
    {6 "Activity" {sort_by_pos} {<td>$short_name</td>}}
    {7 "Reg. State" {sort_by_pos} {<td>[color_reg_state $reg_state]</td>}}
}

#show $display_size registrations at a time
set display_size 250

set return_url "order-history-one.tcl"

if {![exists_and_not_null start_id]} {
    if {[string compare $range_type "reg_id"] == 0} {
	set start_id 0
    } else {
	set start_id ""
    }
}

switch $history_type {
    "date" {
	set bind_vars [ad_tcl_vars_to_ns_set r_date admin_id]
	set reg_range_sql "
	select 
	lower(last_name) as last_name, r.reg_id
	from events_registrations r, events_activities a, events_events e, 
	users u, events_prices p, user_group_map ugm
	where trunc(reg_date) = :r_date
	and e.activity_id = a.activity_id
	and p.event_id = e.event_id
	and u.user_id = r.user_id
	and a.group_id = ugm.group_id
	and ugm.user_id = :admin_id
	and p.price_id = r.price_id
	[ad_dimensional_sql $dimensional where]
	union
	select 
	lower(last_name) as last_name, r.reg_id
	from events_registrations r, events_activities a, events_events e, 
        users u, events_prices p
	where trunc(reg_date) = :r_date
	and e.activity_id = a.activity_id
	and p.event_id = e.event_id
	and u.user_id = r.user_id
	and a.group_id is null
	and p.price_id = r.price_id
	[ad_dimensional_sql $dimensional where]
	$reg_range_order_sql
	"

	set url_vars "[export_url_vars history_type r_date state_filter]"
	set title "Orders for [util_IllustraDatetoPrettyDate $r_date]"
	set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Date"]"
    } "event" {
	set bind_vars [ad_tcl_vars_to_ns_set event_id]
	set reg_range_sql "
	select lower(last_name) as last_name,r.reg_id
	from events_registrations r, events_prices p, users u
	where p.event_id = :event_id
	and p.price_id = r.price_id
	and u.user_id = r.user_id
	[ad_dimensional_sql $dimensional where]
	$reg_range_order_sql
	"

	set url_vars "[export_url_vars history_type event_id state_filter]"
	set title "Order History for [events_pretty_event $event_id]"
	
	set activity_id [db_string sel_activity_id "select
	activity_id from events_events
	where event_id = $event_id"]
	
	set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] [list "order-history-activity.tcl" "By Activity"] [list "order-history-one-activity.tcl?[export_url_vars activity_id]" "Activity"] "Event"]
	"
    } "group" {
	if {[exists_and_not_null group_id]} {
	    set bind_vars [ad_tcl_vars_to_ns_set group_id]
	    set reg_range_sql "
	    select lower(last_name) as last_name, r.reg_id
	    from events_registrations r, events_activities a, 
	    events_events e, users u,
	    events_prices p
	    where a.group_id = :group_id
	    and e.activity_id = a.activity_id
	    and p.event_id = e.event_id
	    and p.price_id = r.price_id
	    and u.user_id = r.user_id
	    [ad_dimensional_sql $dimensional where]
	    $reg_range_order_sql
	    "	    
	} else {
	    #don't really need this, but pass it to keep it from being null
	    set bind_vars "[ad_tcl_vars_to_ns_set admin_id]"
	    set reg_range_sql "
	    select lower(last_name) as last_name, r.reg_id
	    from events_registrations r, events_activities a, 
	    events_events e, users u,
	    events_prices p
	    where a.group_id is null
	    and e.activity_id = a.activity_id
	    and p.event_id = e.event_id
	    and p.price_id = r.price_id
	    and u.user_id = r.user_id
	    [ad_dimensional_sql $dimensional where]
	    $reg_range_order_sql
	    "	   
	}

	if {[exists_and_not_null group_id]} {
	    set group_name [db_string sel_group_name "select group_name
	    from user_groups
	    where group_id = $group_id"]
	} else {
	    set group_name "<i>No Group</i>"
	}
	
	set url_vars "[export_url_vars history_type group_id state_filter]"
	set title "Orders for <i>$group_name</i>"
	set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] [list "order-history-ug.tcl" "User Groups"] "User Group"]"
    } "state" {
	set bind_vars [ad_tcl_vars_to_ns_set r_state admin_id]
	set reg_range_sql "
	select
	lower(last_name) as last_name, r.reg_id
	from events_registrations r, events_prices p,
	events_activities a, events_events e, users u,
	user_group_map ugm
	where p.event_id = e.event_id
	and p.price_id = r.price_id
	and e.activity_id = a.activity_id
	and u.user_id = r.user_id
	and reg_state = :r_state
	and a.group_id = ugm.group_id
	and ugm.user_id = :admin_id
	[ad_dimensional_sql $dimensional where]
	union
	select 
	lower(last_name) as last_name, r.reg_id
	from events_registrations r, events_prices p,
	events_activities a, events_events e, users u
	where p.event_id = e.event_id
	and p.price_id = r.price_id
	and e.activity_id = a.activity_id
	and u.user_id = r.user_id
	and reg_state = :r_state
	and a.group_id is null
	[ad_dimensional_sql $dimensional where]
	$reg_range_order_sql
	"
	
	set url_vars "[export_url_vars history_type r_state state_filter]"
	set title "Order History - For Registration State \"$r_state\""
	set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] [list "order-history-state.tcl" "By Registration State"] "$r_state"]"
    } default {
	#if history_type is null, then display by reg_id
	set bind_vars [ad_tcl_vars_to_ns_set admin_id]
	set reg_range_sql "
	select lower(last_name) as last_name, reg_id
	from events_registrations r, events_activities a, events_events e, 
	users u, events_prices p, user_group_map ugm
	where p.event_id = e.event_id
	and e.activity_id = a.activity_id
	and u.user_id = r.user_id
	and a.group_id = ugm.group_id
	and ugm.user_id = :admin_id
	and p.price_id = r.price_id
	[ad_dimensional_sql $dimensional where]
	union
	select lower(last_name) as last_name, reg_id
	from events_registrations r, events_activities a, events_events e, 
	users u, events_prices p
	where p.event_id = e.event_id
	and e.activity_id = a.activity_id
	and u.user_id = r.user_id
	and a.group_id is null
	and p.price_id = r.price_id
	[ad_dimensional_sql $dimensional where]
	$reg_range_order_sql
	"
	
	set url_vars "[export_url_vars history_type state_filter]"
	set title "Order History - By Registration Number"
	set context_bar "[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "By Registration Number"]"
    }
}

if {[empty_string_p $url_vars]} {
    set pass_in_vars "?range_type="
} else {
    set pass_in_vars "$url_vars&range_type="
}

if {[string compare $range_type "reg_id"] == 0} {
    append pass_in_vars "reg_id"

    set range_bar [events_range_bar_id $start_id $display_size $reg_range_sql $bind_vars $return_url $pass_in_vars]
} else {
    #range_type is last_name
    append pass_in_vars "last_name"

    set range_bar [events_range_bar_name $start_id $display_size $reg_range_sql $bind_vars $return_url $pass_in_vars]
}

#pass in all vars to ad_dimensional except for start_id
set dimen_vars [ns_getform]
if {![empty_string_p $dimen_vars]} {
    set start_id_index [ns_set find $dimen_vars "start_id"]
} else {
    set start_id_index -1
}

if {$start_id_index >= 0} {
    ns_set delete $dimen_vars $start_id_index
}

    
append whole_page "[ad_header "[ad_system_name] $title"]
<h2>$title</h2>
$context_bar
<hr>
<font size=-1><b>Registration Blocks:</b></font> $range_bar
<p>
[ad_dimensional $dimensional "" $dimen_vars]
<p>
"

switch $history_type {
    "date" {
	set select_sql "select 
	r.reg_id, lower(u.last_name), u.email, r.title_at_org,
	r.org, a.short_name, r.reg_state, u.first_names, u.last_name
	from events_registrations r, events_activities a, events_events e, 
	users u, events_prices p, user_group_map ugm
	where trunc(reg_date) = '$r_date'
	and e.activity_id = a.activity_id
	and p.event_id = e.event_id
	and u.user_id = r.user_id
	and a.group_id = ugm.group_id
	and ugm.user_id = $admin_id
	and p.price_id = r.price_id
	[ad_dimensional_sql $dimensional where]
	$reg_id_sql
	union
	select 
	r.reg_id, lower(u.last_name), u.email, r.title_at_org,
	r.org, a.short_name, r.reg_state, u.first_names, u.last_name
	from events_registrations r, events_activities a, events_events e, 
        users u, events_prices p
	where trunc(reg_date) = '$r_date'
	and e.activity_id = a.activity_id
	and p.event_id = e.event_id
	and u.user_id = r.user_id
	and a.group_id is null
	and p.price_id = r.price_id
	[ad_dimensional_sql $dimensional where]
	$reg_id_sql
	[ad_order_by_from_sort_spec $orderby $table_def]"
    }
    "event" {
	set select_sql "select 
	r.reg_id, lower(u.last_name), u.email, r.title_at_org,
	r.org, a.short_name, r.reg_state, u.first_names, u.last_name
	from events_registrations r, events_activities a, events_events e, 
	users u, events_prices p
	where p.event_id = $event_id
	and p.price_id = r.price_id
	and u.user_id = r.user_id
	and e.activity_id = a.activity_id
	and e.event_id = p.event_id
	[ad_dimensional_sql $dimensional where]
	$reg_id_sql
	[ad_order_by_from_sort_spec $orderby $table_def]"
    }
    "group" {
	if {[exists_and_not_null group_id]} {
	    set select_sql "select 
	    r.reg_id, lower(u.last_name), u.email, r.title_at_org,
	    r.org, a.short_name, r.reg_state, u.first_names, u.last_name
	    from events_registrations r, events_activities a, 
	    events_events e, users u,
	    events_prices p
	    where a.group_id = $group_id
	    and e.activity_id = a.activity_id
	    and p.event_id = e.event_id
	    and p.price_id = r.price_id
	    and u.user_id = r.user_id
	    [ad_dimensional_sql $dimensional where]
	    $reg_id_sql
	    [ad_order_by_from_sort_spec $orderby $table_def]"
	} else {
	    set select_sql "select
	    r.reg_id, lower(u.last_name), u.email, r.title_at_org,
	    r.org, a.short_name, r.reg_state, u.first_names, u.last_name
	    from events_registrations r, events_activities a, 
	    events_events e, users u,
	    events_prices p
	    where a.group_id is null
	    and e.activity_id = a.activity_id
	    and p.event_id = e.event_id
	    and p.price_id = r.price_id
	    and u.user_id = r.user_id
	    [ad_dimensional_sql $dimensional where]
	    $reg_id_sql
	    [ad_order_by_from_sort_spec $orderby $table_def]"
	}
	
    }
    "state" {
	set select_sql "
	select 
	r.reg_id, lower(u.last_name), u.email, r.title_at_org,
	r.org, a.short_name, r.reg_state, u.first_names, u.last_name
	from events_registrations r, events_prices p,
	events_activities a, events_events e, users u,
	user_group_map ugm
	where p.event_id = e.event_id
	and p.price_id = r.price_id
	and e.activity_id = a.activity_id
	and u.user_id = r.user_id
	and reg_state = '$r_state'
	and a.group_id = ugm.group_id
	and ugm.user_id = $admin_id
	$reg_id_sql
	union
	select 
	r.reg_id, lower(u.last_name), u.email, r.title_at_org,
	r.org, a.short_name, r.reg_state, u.first_names, u.last_name
	from events_registrations r, events_prices p,
	events_activities a, events_events e, users u
	where p.event_id = e.event_id
	and p.price_id = r.price_id
	and e.activity_id = a.activity_id
	and u.user_id = r.user_id
	and reg_state = '$r_state'
	and a.group_id is null
	$reg_id_sql
	[ad_order_by_from_sort_spec $orderby $table_def]
	"
    }
    default {
	set select_sql "select 
	r.reg_id, lower(u.last_name), u.email, r.title_at_org,
	r.org, a.short_name, r.reg_state, u.first_names, u.last_name
	from events_registrations r, events_activities a, events_events e, 
        users u, events_prices p, user_group_map ugm
	where p.event_id = e.event_id
	and e.activity_id = a.activity_id
	and u.user_id = r.user_id
	and a.group_id = ugm.group_id
	and ugm.user_id = $admin_id
	and p.price_id = r.price_id
	[ad_dimensional_sql $dimensional where]
	$reg_id_sql
	union
        select 
	r.reg_id, lower(u.last_name), u.email, r.title_at_org,
	r.org, a.short_name, r.reg_state, u.first_names, u.last_name
	from events_registrations r, events_activities a, events_events e, 
        users u, events_prices p
	where p.event_id = e.event_id
	and e.activity_id = a.activity_id
	and u.user_id = r.user_id
	and a.group_id is null
	and p.price_id = r.price_id
	[ad_dimensional_sql $dimensional where]
	$reg_id_sql
	[ad_order_by_from_sort_spec $orderby $table_def]
	"
    }
}

append whole_page "
[ad_table -Tcolumns $col -Tmissing_text "<em>There are no registrations to display</em>" -Torderby $orderby regs $select_sql $table_def]
"

#this is inefficient but the only way to get a count...
set count [db_string count_reg "select count(*) from ($select_sql)"]

if {($history_type == "event") && (($state_filter == "waiting") || ($state_filter == "pending")) && ($count > 0)} {
    set state $state_filter
    set pretty_state [ad_decode $state "shipped" "Confirmed" "pending" "Pending" "waiting" "Wait-listed" $state]
    append whole_page "
    <p>
    <ul>
    <li><a href=\"reg-approve-multiple?[export_url_vars event_id state]\">
    Approve all these [string tolower $pretty_state] registrants</a>
    </ul>
    "
}

append whole_page "
[ad_footer]"



doc_return  200 text/html $whole_page

