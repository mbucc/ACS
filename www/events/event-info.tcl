# event-info.tcl

ad_page_contract {
    Displays information about a current event.

    @param event_id the event at which we're looking
    
    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id event-info.tcl,v 3.8.2.6 2000/09/22 01:37:32 kevin Exp
} {
    event_id:integer
}

set sql "
  select a.short_name, 
         a.activity_id, a.description, a.detail_url, 
         v.city, 
         decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location,
         e.start_time, e.end_time, e.reg_deadline,
         e.alternative_reg, e.reg_needs_approval_p,
         e.available_p, e.reg_cancellable_p,
         decode(sign(e.reg_deadline - sysdate),1,'t','f') as current_p,
         decode(e.max_people, null, '', e.max_people) as max_people,
         to_char(e.start_time,'fmDay') as pretty_start_day, 
         to_char(e.end_time,'fmDay') as pretty_end_day, 
         to_char(e.reg_deadline,'fmDay') as pretty_reg_day,
         to_char(e.start_time,'HH12:MI AM') as pretty_start_hour_minute,
         to_char(e.end_time,'HH12:MI AM') as pretty_end_hour_minute,
         to_char(e.reg_deadline,'HH12:MI AM') as pretty_reg_hour_minute
    from events_events e, events_activities a,  events_venues v,
         country_codes cc
   where  e.event_id = :event_id
     and  a.activity_id = e.activity_id
     and  v.venue_id = e.venue_id
     and  cc.iso = v.iso
"

if { [db_0or1row event_get $sql ]==0 } {
    doc_return  200 text/html "[ad_header "Could not find event"]

<font size=+2><b>Could not find event</b></font> in [ad_system_name] 
<br><br>
[ad_context_bar_ws [list "index.tcl" "Events"] "Register"]
<hr>

We can't build you an order form because event
$event_id is not being offered.

[ad_footer]
"
    return
}

# we have a valid event id

if { $available_p == "f" } {
    # event has been discontinued
     doc_return 200 text/html "[ad_header "Event Discontinued"]

<font size=+2><b>Event Discontinued</b></font> in [ad_system_name] 
<br><br>
[ad_context_bar_ws [list "index.tcl" "Events"] "Register"]
<hr>

This event for $short_name is no longer available.  
(You are probably using an old bookmarked page.)  <br>
This event may just have been rescheduled; check the
<a href=\"index\">main events page</a>.

[ad_footer]
"
    return
}

set pretty_event [events_pretty_event $event_id]

append whole_page "
[ad_header "$pretty_event"]
<h2>$pretty_event</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] "Event"]
<hr>
<h3>About the Event</h3>
"

append whole_page "
<input type=hidden name=event_id value=$event_id>

<table>
<tr valign=top>
 <th>When</th>
 <td>$pretty_start_day, [util_AnsiDatetoPrettyDate $start_time], 
 [string trimleft $pretty_start_hour_minute "0"] - <br>
 $pretty_end_day, [util_AnsiDatetoPrettyDate $end_time], 
 [string trimleft $pretty_end_hour_minute "0"]
 </td>
</tr>

<tr valign=top>
 <th>Where</th>
 <td>$city, $big_location (you'll get specifics after you register)</td>
</tr>

<tr valign=top>
 <th>Registration Deadline</th>
 <td><font color=red>$pretty_reg_day, 
 [util_AnsiDatetoPrettyDate $reg_deadline], 
 [string trimleft $pretty_reg_hour_minute "0"]
 </font>
 </td>
</tr>


"

#get the event's public, assigned organizers
set sql "
select
eo.role, eo.user_id, eo.role_id,
u.first_names || ' ' || u.last_name as organizer_name, u.bio
from events_organizers eo, users u
where eo.event_id = :event_id
and eo.public_role_p = 't'
and u.user_id = eo.user_id"

set organizers_text ""
db_foreach organizer_list $sql {
    #only add a link to the bio if there is anything to show
    set bio [string trim $bio]
    if {![empty_string_p $bio]} {
	append organizers_text "<li>$role: <a href=\"organizer?[export_url_vars role_id user_id]\">$organizer_name</a>"
    } else {
	append organizers_text "<li>$role: $organizer_name"
    }
}

if {![empty_string_p $organizers_text]} {
    append whole_page "
    <tr valign=top>
     <th>Organizers</th>
     <td><ul>
     $organizers_text
     </ul>
    </td></tr>
    "
}

set agenda_text "<tr valign=top><th>Event Agenda</th><td>\n<ul>"

set return_url  "/events/order-one.tcl?event_id=$event_id"
set on_which_table "events_events"
set on_what_id "$event_id"

set sql "
 select 
 file_title, file_id 
 from events_file_storage
 where on_which_table = :on_which_table
 and on_what_id = :on_what_id"

set agenda_counter 0
db_foreach file_list $sql {
    append agenda_text "<li>
<a href=\"download?[export_url_vars file_id]\">
$file_title</a>\n"
    
    incr agenda_counter
}
if {$agenda_counter > 0} {
    append agenda_text "\n</ul></td></tr>"
    append whole_page $agenda_text
}

# get the pricing info
#<a name=\"aboutorder\">

append whole_page "
<tr valign=top>
 <th>Price</th>
"

set order_price_html "
<td><ul>
"

set sql "
  select decode(price, 0, 'free', price) as a_price,
         description as product_name, expire_date
    from events_prices
   where event_id = :event_id
   order by price_id"

set price_count 0
set get_credit_card_p 0

db_foreach file_list $sql {
    if {$a_price != "free"} {
	set a_price "$[util_commify_number $a_price]"
	set get_credit_card_p 1
    }

    if {$price_count == 0} {
	append order_price_html "
	<li>$product_name: $a_price
	"
    } else {
	append order_price_html "
	<li>$product_name: $a_price
	"
    }
    incr price_count
}

if {$get_credit_card_p} {
    if {$price_count == 1} {
	append whole_page "<td>$product_name ($a_price)</td>"

    } elseif {$price_count >= 1} {
	append whole_page "$order_price_html</ul></td></tr>"

    }    
} else {
    append whole_page "<td>free</td></tr>"
}

if { ![empty_string_p $detail_url] } {
    append whole_page "<tr valign=top>
    <th>Related web-site</th>
    <td><a href=\"$detail_url\">$detail_url</a>
    </td></tr>
    "
}


append whole_page "\n</table>\n "

if { ![empty_string_p $description] } {
    append whole_page "<p>$description "
}


if {[string compare $current_p "t"] == 0} {
    append whole_page "
    <p>
    <h3>Register For This Event</h3>
    <ul>
    <li><a href=\"order-one?[export_url_vars event_id]\">Register 
    for this event</a>
    </ul>
    "
} else {
    append whole_page "
    <p>
    <h3>Registration Ended</h3>
    Registration for this event is over.  Try signing up
    for a future event
    "
}

append whole_page "
[ad_footer]
"

db_release_unused_handles
doc_return 200 text/html $whole_page