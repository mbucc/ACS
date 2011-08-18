set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

#collect the whole page
set whole_page "[ad_header "[ad_system_name] Events"]

<h2>[ad_system_name] Events</h2>

[ad_context_bar_ws "Events"]

<hr>

<ul>
"

set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]


set selection [ns_db select $db "select
  evnt.event_id, 
  evnt.start_time, 
  to_char(evnt.start_time,'fmDay') as pretty_day,
  to_char(evnt.start_time,'HH12:MI AM') as pretty_start_hour_minute,
  evnt.activity_id,
  act.short_name,
  v.city,
  v.usps_abbrev,
  v.iso
from events_events evnt, events_activities act, 
events_venues v
where evnt.reg_deadline > sysdate
and act.activity_id = evnt.activity_id
and act.group_id is null
and v.venue_id = evnt.venue_id
and evnt.available_p <> 'f'
order by evnt.start_time, v.city
"]

set event_count 0

append whole_page "<h4>[ad_system_name] Events</h4><table>"
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append whole_page "
    <tr>
     <td><a href=\"order-one.tcl?event_id=$event_id\">$short_name</a> &nbsp;
     <td valign=top>[events_pretty_location $db_sub $city $usps_abbrev $iso]
     <td>$pretty_day, [util_AnsiDatetoPrettyDate $start_time]
    "
    incr event_count
}

append whole_page "</table>"
    


set selection [ns_db select $db "select 
  evnt.event_id, 
  evnt.start_time, 
  to_char(evnt.start_time,'fmDay') as pretty_day,
  to_char(evnt.start_time,'HH12:MI AM') as pretty_start_hour_minute,
  evnt.activity_id,
  act.short_name,
  grps.group_name,
  v.city,
  v.usps_abbrev,
  v.iso
from events_events evnt, events_activities act, 
user_groups grps, events_venues v
where evnt.reg_deadline > sysdate
and act.activity_id = evnt.activity_id
and grps.group_id = act.group_id
and v.venue_id = evnt.venue_id
and evnt.available_p <> 'f'
order by upper(group_name), evnt.start_time, v.city
"]



#set last_organizer ""
set last_group ""
set first_iteration_p 1
set last_city_state ""
set last_activity_id ""

while { [ns_db getrow $db $selection] } {
    incr event_count
    set_variables_after_query

    if {![exists_and_not_null group_name]} {
	set group_name "Public"
    }

    if { $last_group != $group_name } {
	if !$first_iteration_p {
	    append whole_page "</table>"
	}
	append whole_page "<h4>$group_name</h4><table>"
	#append whole_page "<h4>$organizer_name</h4><table>"
	
	set last_group $group_name
	#set last_organizer $organizer_name
        set last_city_state ""
        set need_separation_p 0
    } else {
	# another row from the same organizer, so we'll need
	# a separator row if we move to a new city	
	set need_separation_p 1
    }
    

    set city_state [events_pretty_location $db_sub $city $usps_abbrev $iso]
    
    set last_activity_id $activity_id
    if $need_separation_p {
	# print a separator row
	append whole_page "<tr><td colspan=3>&nbsp;</tr>\n"
    }
    # print most of the row but leave the last cell open
    append whole_page "<tr>
    <td><a href=\"order-one.tcl?event_id=$event_id\">$short_name</a> &nbsp;
    <td valign=top>$city_state
    <td>$pretty_day, [util_AnsiDatetoPrettyDate $start_time]
    "
    
    if { [string match "*PM*" $pretty_start_hour_minute] } {
	# starts in the afternoon
	append whole_page " at [string trimleft $pretty_start_hour_minute "0"]\n"
    }
    set last_city_state $city_state
    set first_iteration_p 0
}

if !$first_iteration_p {
    append whole_page "</table>"
}



if {$event_count == 0} {
    append whole_page "<li>There are no events currently available."
}

append whole_page "</ul>
[ad_footer]"

ns_db releasehandle $db
ns_db releasehandle $db_sub

ReturnHeaders
ns_write $whole_page