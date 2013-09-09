# events/index.tcl

ad_page_contract {
    Purpose:  Displays all upcoming events to the user, grouped by 
              the administration group they fall under.
    Note:  Events that start after noon are considered to be 'not all day'
           in a sense that merits showing their start time on the main
           events page.  Multi-day events have start and end days shown.

    There was a system for inserting separator rows if a number
    of events by the same organizing group are in different cities...
    This wasn't done consistently, so it's been removed.
    The old variable used for this was need_separation_p, 
    like so:   if $need_separation_p {
                  append whole_page "<tr><td colspan=3>&nbsp;</tr>\n" }

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id index.tcl,v 3.18.2.4 2000/09/22 01:37:32 kevin Exp
} {

}

#set security_current_url [ns_conn url]
#ad_return_error "url" "$security_current_url"
#return

## not checking for user_id until a visitor tries to register
#set user_id [ad_verify_and_get_user_id]
#ad_maybe_redirect_for_registration

#collect the whole page
set whole_page "[ad_header "[ad_system_name] Events"]

<h2>[ad_system_name] Events</h2>
[ad_context_bar_ws "Events"]
<hr>
"

set event_count 0
    
## select activities with owning groups

set sql "
select
evnt.event_id, evnt.start_time, evnt.end_time,
decode(to_char(evnt.end_time, 'DD'), to_char(evnt.start_time, 'DD'), 1, 0) as same_day_p,
(evnt.end_time - evnt.start_time) as duration,
to_char(evnt.start_time,'Dy') as pretty_day,
to_char(evnt.end_time,'Dy') as pretty_end_day,
to_char(evnt.start_time,'HH12:MI AM') as pretty_start_hour_minute,
to_char(evnt.end_time,'HH12:MI AM') as pretty_end_hour_minute,
evnt.activity_id,
act.short_name,
grps.group_name,
v.city, 
decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location
from events_events evnt, events_activities act, 
user_groups grps, events_venues v, country_codes cc
where evnt.reg_deadline > sysdate
and act.activity_id = evnt.activity_id
and grps.group_id = act.group_id
and v.venue_id = evnt.venue_id
and evnt.available_p <> 'f'
and cc.iso = v.iso
order by upper(group_name) desc, evnt.start_time, v.city
"

#set last_organizer ""
set last_group ""
set first_iteration_p 1
set last_city_state ""
set last_activity_id ""

# events are ordered first by group, so we take advantage of this
# and look for a change in group_name to trigger formatting changes.
append whole_page "<table cellspacing=5>"

db_foreach list_of_events $sql {
    incr event_count
    if {![exists_and_not_null group_name]} { set group_name "Public" }

    if { $last_group != $group_name } {
	if !$first_iteration_p { append whole_page "<tr><td>&nbsp </td></tr>" }

	append whole_page "
	<tr><td colspan=3 valign=bottom align=left>
	<h4>$group_name</h4>
	</td></tr>
	"
	set last_group $group_name

	#append whole_page "<h4>$organizer_name</h4><table>"
	#set last_organizer $organizer_name

        set last_city_state ""
    }

    #set city_state [events_pretty_location_sub $city $usps_abbrev $iso]
    set city_state "$city, $big_location"
    set last_activity_id $activity_id

    # print most of the row but leave the last cell open
    append whole_page "<tr>
     <td valign=top><a href=\"event-info?event_id=$event_id\">$short_name</a> &nbsp;
     <td valign=top>$city_state
     <td valign=top>$pretty_day. [util_AnsiDatetoPrettyDate $start_time]"

    if { ($duration >= 1) || ($same_day_p != 1)} {
	append whole_page "&nbsp;&nbsp;-&nbsp&nbsp; $pretty_end_day.
             [util_AnsiDatetoPrettyDate $end_time]" 
    } else {
      append whole_page " ([string trimleft $pretty_start_hour_minute "0"] -
	[string trimleft $pretty_end_hour_minute "0"])\n"
    }

    set last_city_state $city_state
    set first_iteration_p 0
}

# unless the last selection was null (no specific events), close a table.
#if !$first_iteration_p { append whole_page "</table>" }

###
set sql "
select
evnt.event_id, evnt.start_time, evnt.end_time,
decode(to_char(evnt.end_time, 'DD'), to_char(evnt.start_time, 'DD'), 1, 0) as same_day_p,
(evnt.end_time - evnt.start_time) as duration,
to_char(evnt.start_time,'Dy') as pretty_day,
to_char(evnt.end_time,'Dy') as pretty_end_day,
to_char(evnt.start_time,'HH12:MI AM') as pretty_start_hour_minute,
to_char(evnt.end_time,'HH12:MI AM') as pretty_end_hour_minute,
evnt.activity_id,
act.short_name,
v.city, 
decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location
from events_events evnt, events_activities act, events_venues v,
country_codes cc
where evnt.reg_deadline > sysdate
and act.activity_id = evnt.activity_id
and act.group_id is null
and v.venue_id = evnt.venue_id
and evnt.available_p <> 'f'
and cc.iso = v.iso
order by evnt.start_time, v.city
"

set other_events ""
set other_count 0
append other_events "
<tr><td>&nbsp </td></tr>
<tr><td colspan=3 valign=bottom align=left>
<h4>Other [ad_system_name] Events</h4>
</td></tr>"


db_foreach list_of_events_2 $sql {
    append other_events "
    <tr>
     <td valign=top><a href=\"event-info?event_id=$event_id\">$short_name</a> &nbsp;
     <td valign=top>$city, $big_location
     <td valign=top>$pretty_day. [util_AnsiDatetoPrettyDate $start_time] "

    if { ($duration >= 1) || ($same_day_p != 1)} {
        append other_events "&nbsp;&nbsp;-&nbsp&nbsp; $pretty_end_day.
             [util_AnsiDatetoPrettyDate $end_time]"
    } else {
      append other_events "
	([string trimleft $pretty_start_hour_minute "0"] -
	[string trimleft $pretty_end_hour_minute "0"])\n"
    }
    incr other_count
    incr event_count
}
# if there are any other events going on
if {$other_count > 0} { append whole_page $other_events }

append whole_page "</table>"

# if there are no events of any kinD
if {$event_count == 0} {
    append whole_page "<li>There are no events currently available."
}

## clean up.

append whole_page "\n [ad_footer]"



doc_return  200 text/html $whole_page

##### File Over
