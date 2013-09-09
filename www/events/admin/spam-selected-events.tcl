# File:  events/admin/spam-selected-events.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Select events to spam. 
#####

#perhaps orderby
#perhaps event_id if we only want to spam one event

ad_page_contract {
    Select events to spam.

    @param orderby order param for ad_table
    @param event_id optionally, the event to spam if we only want to spam one event

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id spam-selected-events.tcl,v 3.16.2.5 2000/09/22 01:37:40 kevin Exp
} {
    {orderby "short_name"}
    {event_id:integer,optional}
}

set admin_id [ad_maybe_redirect_for_registration]

if {![exists_and_not_null orderby]} {
    set orderby "short_name"
}


set whole_page ""
append whole_page "[ad_header "Spam Selected Events"]"

append whole_page "
  <h2>Spam Selected Events</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Spam Selected Events"]
<hr>"

if {[exists_and_not_null event_id]} {
    set event_sql_filter "and event_id = $event_id"

    #the table definition for ad_table
    set table_def {
	{check_box "" {no_sort} {<td><input type=checkbox checked name="event.$event_id" value=$event_id></td>}}
	{short_name "Activity" {upper_name $order} {<td>$short_name</td>}}
	{city "Location" {upper_city $order} {<td>$city, $big_location</td>}}
	{start_time "Start" {} {<td>[util_AnsiDatetoPrettyDate $start_time]</td>}}
	{end_time "End" {} {<td>[util_AnsiDatetoPrettyDate $end_time]</td>}}
    }

} else {
    #this is for stuffing into the spam module
    set sql_post_select "select distinct 
    users.email, users.user_id, users.email_type
    from users_spammable users, events_reg_not_canceled r
    where users.user_id = r.user_id
    and r.reg_id not in 
      (select distinct r.reg_id
      from events_registrations r,events_activities a, events_events e,
      events_prices p
      where p.event_id = e.event_id
      and e.activity_id = a.activity_id
      and p.price_id = r.price_id
      and a.group_id not in 
         (select distinct group_id 
         from user_group_map 
         where user_id = $admin_id) )
    order by users.user_id
    "    
    append whole_page "   
    Select the event(s) whose registrants you would like to spam<p>
    or 
    <form method=post action=\"spam/action-choose.tcl\">
    [export_form_vars sql_post_select]
    <input type=submit value=\"Spam Everyone\">
    </form>
    "

    #the table definition for ad_table
    set table_def {
	{check_box "" {no_sort} {<td><input type=checkbox name="event.$event_id" value=$event_id></td>}}
	{short_name "Activity" {upper_name $order} {<td>$short_name</td>}}
	{city "Location" {upper_city $order} {<td>$city, $big_location</td>}}
	{start_time "Start" {} {<td>[util_AnsiDatetoPrettyDate $start_time]</td>}}
	{end_time "End" {} {<td>[util_AnsiDatetoPrettyDate $end_time]</td>}}
    }

    set event_sql_filter ""
}

append whole_page "
<form method=post action=\"spam/action-choose.tcl\">
[philg_hidden_input spam_selected_events 1]
"

if {![exists_and_not_null state_filter]} {
    set state_filter "all"
}

#dimensional filter for which conferences to show
set dimensional {
    {state_filter "Show Events Starting in the:" all {
	    {last_month "Last Month" {where "start_time > sysdate - 32 and start_time <= sysdate"}}
	    {last_6_months "Last 6 Months" {where "start_time > sysdate - 187 and start_time <= sysdate"}}
	    {last_year "Last Year" {where "start_time > sysdate - 366 and start_time <= sysdate"}}
	    {future "Future" {where "start_time > sysdate"}}
	    {all "All" {}}
	}
    }
}


#the columns for ad_table
set col [list check_box short_name city start_time end_time]

set sql "select 
upper(a.short_name) as upper_name, upper(v.city) as upper_city,
e.event_id, e.start_time, e.end_time,
v.city, 
decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location,
a.short_name
from events_activities a, events_events e, events_venues v,
country_codes cc,
user_groups ug, user_group_map ugm
where a.activity_id = e.activity_id
and a.group_id = ugm.group_id
and ugm.group_id = ug.group_id
and ugm.user_id = :admin_id
and v.venue_id = e.venue_id
and cc.iso = v.iso
$event_sql_filter
[ad_dimensional_sql $dimensional where]
union
select 
upper(a.short_name) as upper_name, upper(v.city) as upper_city,
e.event_id, e.start_time, e.end_time,
v.city, 
decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location,
a.short_name
from events_activities a, events_events e, events_venues v,
country_codes cc
where a.activity_id = e.activity_id
and a.group_id is null
and v.venue_id = e.venue_id
and cc.iso = v.iso
$event_sql_filter
[ad_dimensional_sql $dimensional where]
[ad_order_by_from_sort_spec $orderby $table_def]
"

set bind_vars [ad_tcl_vars_to_ns_set admin_id]

append whole_page "
[ad_dimensional $dimensional]
<p>
[ad_table -bind $bind_vars -Tcolumns $col -Tmissing_text "<em>There are no current events to display</em>" -Torderby $orderby sel_events $sql $table_def]
"

append whole_page "
<p>
Do you want to spam:
<p>
<input type=radio checked name=reg_state value=\"shipped\">Confirmed Registrants<br>
<input type=radio name=reg_state value=\"pending\">Pending Registrants<br>
<input type=radio name=reg_state value=\"waiting\">Wait-Listed Registrants<br>
<input type=radio name=reg_state value=\"all\">All Registrants<br>
"

## clean up, return page

append whole_page "
<center> <input type=submit value=\"Continue\"> </center>
</form>
[ad_footer]"



doc_return  200 text/html $whole_page
##### EOF
