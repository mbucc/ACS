set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_the_usual_form_variables
#event_id

#events_makesecure 

if {![exists_and_not_null event_id] } {
    ns_return 200 text/html "[ad_header "No event id"]

<h2>No event id</h2>

specified for [ad_system_name]

<hr>

We can't build you an order form because this request came in with no
event id.  Please hassle the person who built the preceding page.

[ad_footer]
"
    return
}

set db [ns_db gethandle]

set selection [ns_db 1row $db "select 
ha_line1, ha_line2, ha_city, ha_state,
ha_postal_code, ha_country_code,
home_phone,
email,
first_names || ' ' || last_name as user_name
from users_contact uc, users u
where u.user_id = uc.user_id(+)
and u.user_id = $user_id"]
set_variables_after_query

if {[empty_string_p $ha_country_code]} {
    set ha_country_code "us"
}


set selection [ns_db 0or1row $db "select 
  a.short_name, 
  v.city, 
  v.usps_abbrev, 
  v.iso,
  v.venue_id,
  e.start_time, 
  e.end_time,
  e.reg_deadline,
  e.alternative_reg,
  decode(e.max_people, null, '', e.max_people) as max_people,
  e.reg_needs_approval_p,
  to_char(e.start_time,'fmDay') as pretty_start_day, 
  to_char(e.end_time,'fmDay') as pretty_end_day, 
  to_char(e.reg_deadline,'fmDay') as pretty_reg_day, 
  to_char(e.start_time,'HH12:MI AM') as pretty_start_hour_minute,
  to_char(e.end_time,'HH12:MI AM') as pretty_end_hour_minute,
  to_char(e.reg_deadline,'HH12:MI AM') as pretty_reg_hour_minute,
  a.activity_id, 
  a.description,
  a.detail_url, 
  e.available_p,
  e.reg_cancellable_p
from events_events e, events_activities a,  events_venues v
where e.event_id = $event_id
and e.available_p <> 'f'
and a.activity_id = e.activity_id
and v.venue_id = e.venue_id
and sysdate < reg_deadline
"]

if { [empty_string_p $selection]} {
     ns_return 200 text/html "[ad_header "Could not find event"]

<h2>Could not find event</h2>

in [ad_system_name]

<hr>

We can't build you an order form because event
$event_id is not being offered.

[ad_footer]
"
    return
}

# we have a valid event id
set_variables_after_query

# we have all the description info from the RDBMS

if { $available_p == "f" } {
    # event has been discontinued
     ns_return 200 text/html "[ad_header "Event Discontinued"]

<h2>Event Discontinued</h2>

in [ad_system_name]

<hr>

This event for $short_name is no longer available.  You're
probably using an old bookmarked page.

[ad_footer]
"
    return
}

# OK, we're set now!

# we generate a reg_id here so that we can trivially detect
# duplicate submissions

set reg_id [database_to_tcl_string $db "select events_reg_id_sequence.nextval from dual"]
set order_id [database_to_tcl_string $db "select events_orders_id_sequence.nextval from dual"]

#collect the whole page
set whole_page "[ad_header "Register"]

<h2>Register</h2>

for <a href=\"activity.tcl?activity_id=$activity_id\"><i>$short_name</i></a>
in [events_pretty_location $db $city $usps_abbrev $iso]<br>

<hr>

"

set selection [ns_db 0or1row $db "select count(reg_id) as num_registered
from events_registrations r, events_prices p
where p.event_id = $event_id
and r.price_id = p.price_id"]
set_variables_after_query

if {$reg_cancellable_p != "t"} {
    append whole_page "<p><font color=red>Note: Registrations for this event cannot 
    be canceled.  Once you register, you are committed to coming.</font>"
}

if {![empty_string_p $max_people]} {
    if {$num_registered >= $max_people} {
	append whole_page "<p><font color=red>Note: This event has already
	received its maximum number of registrations.  If you register
	for this event, you will be placed on a waiting list.</font>"
    }
}

if {$reg_needs_approval_p == "t"} {
    append whole_page "<p><font color=red>Note: A registration for this event
    requires final approval from an administrator.  If you sign up
    for $short_name, your final registration will be pending
    administrator approval.</font>"
}

if { [string length $description] > 400 } {
    append whole_page "<blockquote>
In a hurry?  <a href=\"#aboutorder\">skip to the registration form</a>
</blockquote>
"
}


set target_url "order-one-2.tcl"
set submit_button "Register"


append whole_page "
<form method=post action=\"$target_url\">
[export_form_vars reg_id user_id order_id]

<h3>About the Activity</h3>

<ul>
"

if { ![empty_string_p $description] } {
    append whole_page "<li>
$description
"
}

if { ![empty_string_p $detail_url] } {
    append whole_page "<br><br>\n(<a href=\"$detail_url\">Related web-site</a>)"
}

append whole_page "<p><li>Start Date:  $pretty_start_day, [util_AnsiDatetoPrettyDate $start_time], [string trimleft $pretty_start_hour_minute "0"]
<input type=hidden name=event_id value=$event_id>
<li>End Date:  $pretty_end_day, [util_AnsiDatetoPrettyDate $end_time], [string trimleft $pretty_end_hour_minute "0"]
<li><b>Registration Deadline</b>:  $pretty_reg_day, [util_AnsiDatetoPrettyDate $reg_deadline], [string trimleft $pretty_reg_hour_minute "0"]

"

append whole_page "<li>[events_pretty_location $db $city $usps_abbrev $iso]
(you'll get specifics after you register)


"

set agenda_text "<li>Event Agendas:
<ul>"

set return_url "/events/order-one.tcl?event_id=$event_id"
set on_which_table "events_events"
set on_what_id "$event_id"

set selection [ns_db select $db "select 
file_title, file_id 
from events_file_storage
where on_which_table = '$on_which_table'
and on_what_id = '$on_what_id'"]

set agenda_counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append agenda_text "<li>
    <a href=\"/attach-file/download.tcl?[export_url_vars file_id]\">
    $file_title</a>\n"
    
    incr agenda_counter
}
if {$agenda_counter > 0} {
    append agenda_text "\n</ul>"
    append whole_page $agenda_text
}

append whole_page "\n</ul></ul>\n
"

#get the pricing info
#<a name=\"aboutorder\">
set order_html "

<h3>About Your Order</h3>
"
set order_price_html "
Please select the price for which you would like to register.
<p>
<table cellpadding=5>
"

set selection [ns_db select $db "select
price_id,
decode(price, 0, 'free', price) as a_price,
description as product_name, expire_date
from events_prices
where event_id = $event_id
order by price_id
"]

set price_count 0
set get_credit_card_p 0

set price_count 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if {$a_price != "free"} {
	set a_price "$[util_commify_number $a_price]"
	set get_credit_card_p 1
    }

    if {$price_count == 0} {
	append order_price_html "
	<tr>
	<td><input type=radio checked name=price_id value=$price_id>
	$product_name: $a_price
	"
    } else {
	append order_price_html "
	<tr>
	<td><input type=radio name=price_id value=$price_id>
	$product_name: $a_price
	"
    }
   
    incr price_count
}


if {$get_credit_card_p} {
    if {$price_count == 1} {
	append whole_page $order_html
	append whole_page "<li>Register for $product_name ($a_price)"
	append whole_page "</table>
	[philg_hidden_input price_id $price_id]
	"
    } elseif {$price_count >= 1} {
	append whole_page $order_html
	append whole_page $order_price_html
	append whole_page "</table>"
    }
    
    if {$price_count > 1} {
	append whole_page "
	<font color=red>If you register with a price for which you do
	not qualify, you will still be charged that price.  But, you may 
	be asked to leave the event.</font>"
    }
} else {
    append whole_page "</table><ul><li>Cost: FREE</ul>
    [philg_hidden_input price_id $price_id]"
}


append whole_page "
<a name=\"aboutorder\">
<h3>About You</h3>
</a>

<table>
<tr>
 <td>Name</td>
 <td>$user_name
<tr>
 <td>Email</td>
 <td>$email
<tr>
 <td>Telephone number</td>
 <td><input type=text size=15 name=phone_number value=\"$home_phone\"></td>
<tr>
 <td valign=top>What is your organization?
 <td><input type=text name=org size=30>
<tr>
 <td valign=top>What is your title or main job description?
 <td><input type=text name=title_at_org size=50>
<tr>
 <td valign=top>Where did you hear<br>about this activity?<br>
 <td><input type=text name=where_heard size=50>
<tr>
 <td valign=top>Reason for attending:<br>
 <td><textarea name=attending_reason cols=40 rows=5 wrap=soft></textarea>
<tr>
 <td>Need a hotel?
 <td><input type=checkbox name=need_hotel_p value=t>
<tr>
 <td>Need a rental car?
 <td><input type=checkbox name=need_car_p value=t>
<tr>
 <td>Need a flight?
 <td><input type=checkbox name=need_plane_p value=t>
"    
set selection [ns_db select $db "
select column_name, pretty_name,
column_type, column_actual_type, column_extra,
sort_key
from events_event_fields
where event_id = $event_id
order by sort_key
"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    append whole_page "
    <tr>
     <td>$pretty_name
     <td>[ad_user_group_type_field_form_element $column_name $column_type]"
}



append whole_page "</table><h3>Mailing Address</h3>\n\n"


append whole_page "
<table>
<tr>
  <td>Line 1
  <td><input type=text size=60 name=line1 value=\"$ha_line1\">
<tr>
  <td>Line 2
  <td><input type=text size=60 name=line2 value=\"$ha_line2\">
<tr>
  <td>City
  <td><input type=text size=15 name=city value=\"$ha_city\">
      State <input type=text size=15 name=state value=\"$ha_state\">
      Postal Code <input type=text size=10 name=postal_code value=\"$ha_postal_code\">
<tr>
  <td>Country
  <td>[country_widget $db $ha_country_code]
</table>


"
append whole_page "
<br>
<br>

<center>
<input type=submit value=\"$submit_button\">
</center>
</form>
"

#see if there is another way to register
if {![empty_string_p $alternative_reg]} {
    append whole_page "<p>
    <h4>Alternative Registration</h4>
    $alternative_reg"
}

append whole_page "
[ad_footer]
"

ns_db releasehandle $db
ReturnHeaders
ns_write $whole_page