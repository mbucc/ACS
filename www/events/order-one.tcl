# events/order-one.tcl  
# Purpose:  To allow users to order an event.
#####

ad_page_contract {
    Registration form for an event.

    @param event_id the event for which the user is signing up

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-one.tcl,v 3.19.2.5 2000/09/22 01:37:33 kevin Exp
} {
    {event_id:integer,notnull}
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

#events_makesecure 

if {![exists_and_not_null event_id] } {
    ad_return_warning "No Event ID" "
    We can't build you an order form because this request came in with no
    event id."

    return
}



#check to see if this person has already registered
set reg_check [db_0or1row "evnt_order_check" "select 
	reg_id, reg_date, reg_cancellable_p
   from events_registrations r, events_prices p, events_events e
  where  p.price_id = r.price_id
    and  p.event_id=:event_id
    and  r.user_id=:user_id
    and  e.event_id = :event_id
    and  reg_state <> 'canceled'
"]

if {$reg_check > 0} {
    # he's already registered

    db_release_unused_handles
    set whole_page "
       [ad_header "Already Registered"]
       <h2>Already Registered</h2>
       [ad_context_bar_ws [list "index.tcl" "Events"] "Register"]
       <hr>

        You have already registered for this event on 
       [util_AnsiDatetoPrettyDate $reg_date].
       <p>
        If you'd like, you may:
       <ul>
       <li><a href=\"order-check?[export_url_vars reg_id]\">Review your registration status and information about this event</a>
       <li><a href=\"order-update?[export_url_vars reg_id]\">Update your registration information</a>
    "
    if {$reg_cancellable_p == "t"} {
      append whole_page "
       <li><a href=\"order-cancel?[export_url_vars reg_id]\">
       Cancel your registration</a>"
    }
 
    append whole_page " </ul> [ad_footer]"
    doc_return  200 text/html $whole_page
    
   return;
}

db_1row "evnt_sel_contact" "
  select ha_line1, ha_line2, ha_city, ha_state,
         ha_postal_code, ha_country_code,
         home_phone, email,
         first_names || ' ' || last_name as user_name
    from users_contact uc, users u
   where u.user_id = uc.user_id(+)
     and u.user_id = :user_id"

if {[empty_string_p $ha_country_code]} {
    set ha_country_code "us"
}

set event_check [db_0or1row evnt_sel_evnt_info "
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
"]

if {!$event_check} {
    db_release_unused_handles
    ad_return_warning "Could Not Find Event" "
    We can't build you an order form because event
    $event_id is not being offered.
    "
    return
}

if { $current_p == "f" } {
    # event registration is over 
    db_release_unused_handles
    ad_return_warning "Registration Ended" "
    Registration for this $short_name event is over.  
    Try signing up for a future event.
    "
    return
}

if { $available_p == "f" } {
    # event has been discontinued
    db_release_unused_handles
    ad_return_warning "Event Discontinued" "
    This event for $short_name is no longer available.  
    (You are probably using an old bookmarked page.)  <br>
    This event may just have been rescheduled; check the
    <a href=\"index\">main events page</a>.
    "
    return
}

# Else the event is on.   

#collect the whole page
set whole_page "[ad_header "Register"]

<font size=+2><b>Register</b></font>
   for <a href=\"activity?activity_id=$activity_id\">
       <i>$short_name</i></a>
   in $city, $big_location
<br><br>
[ad_context_bar_ws [list "index.tcl" "Events"] "Register"]
<hr>
"

db_1row evnt_num_reg  "
  select count(reg_id) as num_registered
    from events_reg_shipped r, events_prices p
   where p.event_id = :event_id
     and r.price_id = p.price_id"

if {$reg_cancellable_p != "t"} {
    append whole_page "
<p><font color=red>Note: Registrations for this event cannot 
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

#if { [string length $description] > 400 } {
#    append whole_page "
#<blockquote>
#In a hurry?  <a href=\"#aboutorder\">skip to the registration form</a>
#</blockquote>
#"
#}

#set target_url "order-one-2.tcl"
#set submit_button "Register"

append whole_page "
  <form method=post action=\"order-one-2\">
[export_form_vars reg_id user_id order_id]

<h3>About the Event</h3>
"

#if { ![empty_string_p $description] } {
#    append whole_page " <li>\n $description "
#}

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
# get the pricing info
#<a name=\"aboutorder\">

set order_html "</table>\n <h3>About Your Order</h3> \n"
set order_price_html "
Please select the price for which you would like to register.
<p>
<table cellpadding=5>
"

set price_count 0
set get_credit_card_p 0

db_foreach evnt_sel_prices "
  select price_id, decode(price, 0, 'free', price) as a_price,
         description as product_name, expire_date
    from events_prices
   where event_id = :event_id
   order by price_id" {
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
    append whole_page "<tr valign=top><th>Price</th><td>free</td></tr>
    [philg_hidden_input price_id $price_id]
    </table>
    "
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
 <td valign=top>Organization
 <td><input type=text name=org size=50>
<tr>
 <td valign=top>Title/Job Description
 <td><input type=text name=title_at_org size=50>
<tr>
 <td valign=top>Where did you hear<br>about this activity?<br>
 <td><input type=text name=where_heard size=50>
<tr>
 <td valign=top>Reason for attending:<br>
 <td><textarea name=attending_reason cols=40 rows=5 wrap=soft></textarea>

<input type=hidden name=need_hotel_p value=f>
<input type=hidden name=need_car_p value=f>
<input type=hidden name=need_plane_p value=f>
"    

db_foreach evnt_sel_fields "
  select column_name, pretty_name, column_type, column_actual_type, 
         column_extra, sort_key
    from events_event_fields
   where event_id = :event_id
   order by sort_key " {
       #we'll prepend "customfield" to each column_name so that 
       #we can grab these custom fields as array vars
       #on the next page, using ad_page_contract
    append whole_page "
    <tr><td>$pretty_name
        <td>[ad_user_group_type_field_form_element customfield.$column_name $column_type]"
}

append whole_page "</table>

<h3>Mailing Address</h3>\n
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
      State [events_state_widget $ha_state]
      Postal Code <input type=text size=10 name=postal_code value=\"$ha_postal_code\">
<tr>
  <td>Country
  <td>[country_widget $ha_country_code]
</table>

<br>
<center> <input type=submit value=\"Register\"> </center>
</form>
"

#see if there is another way to register
if {![empty_string_p $alternative_reg]} {
    append whole_page "<p>
      <h4>Alternative Registration</h4>
      $alternative_reg"
}

## clean up.

append whole_page " [ad_footer] "

db_release_unused_handles
doc_return 200 text/html $whole_page
##### EOF
