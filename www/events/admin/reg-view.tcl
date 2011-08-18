set_the_usual_form_variables
#reg_id

if { ![exists_and_not_null reg_id]} {
    ns_return 200 text/html "[ad_header "No registration id"]

<h2>No registration id</h2>

specified for [ad_system_name]

<hr>

Registration id needed.  This request came in with no
registration id.

[ad_footer]
"
    return
}


set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

set selection [ns_db 0or1row $db "select 
u.user_id,
e.event_id,
r.reg_state, 
r.need_hotel_p, r.need_plane_p, r.need_car_p,
to_char(r.reg_date,'YYYY-MM-DD HH24:MI:SS') as reg_date, 
to_char(r.shipped_date,'YYYY-MM-DD HH24:MI:SS') as shipped_date, 
u.first_names, u.last_name, u.email, uc.home_phone, 
uc.ha_line1, uc.ha_line2, 
uc.ha_city, uc.ha_state, 
uc.ha_postal_code, uc.ha_country_code,
r.attending_reason, r.where_heard, r.comments
from events_registrations r, events_events e,
users u, users_contact uc, events_prices p
where r.reg_id = $reg_id
and p.price_id = r.price_id
and e.event_id = p.event_id
and u.user_id = r.user_id
and uc.user_id = r.user_id
"]

if { $selection == "" } {
     ns_db releasehandle $db
     ns_db releasehandle $db_sub
     ns_return 200 text/html "[ad_header "Could not find registration"]

<h2>Could not find registration</h2>

in [ad_system_name]

<hr>

Registration $reg_id was not found in the database.

[ad_footer]
"
    return
}

# we have a valid order id

set_variables_after_query

#if {$canceled_p == "t"} {
#    set canceled_text "(canceled)"
#} else {
#    set canceled_text ""
#}

# we have all the description info from the RDBMS

set event [events_pretty_event $db $event_id]
regsub -all " from " $event "<br>from " event

#release the handles for ad_header
ns_db releasehandle $db
ns_db releasehandle $db_sub
ReturnHeaders

ns_write "[ad_header "Registration # $reg_id ($reg_state)" ]"

set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]


ns_write "
<h2>Registration # $reg_id ($reg_state)</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "Registration"]

<hr>

<table width=100%>
<tr><td valign=top>

<h3>Event Information</h3>
$event
"


ns_write "

<h3>Registration Information</h3>
<table>
<tr>
 <th>Registration State</td>
"
if {$reg_state == "pending"} {
    ns_write "<td><font color=red>$reg_state</font>"
} else {
    ns_write "<td>$reg_state"
}
ns_write "
<tr>
 <th>Registration Date</td>
 <td>$reg_date</td>
"

ns_write "
</table>

</td><td valign=top>

<h3>Customer Information</h3>

<table>
<tr>
 <th>Name</th>
 <td><a href=\"order-same-person.tcl?[export_url_vars user_id]\">$first_names $last_name</a></td>
</tr>
<tr>
 <th>Email</th>
 <td><a href=\"mailto:$email\">$email</a></td>
</tr>
<tr>
 <th>Telephone number</th>
 <td>$home_phone</td>
</th>
<tr>
  <th>Address</th>
  <td>$ha_line1</td>
</tr>
"
if {$ha_line2 != ""} {
    ns_write "<tr><td>&nbsp;</td><td>$ha_line2</td>"
}

ns_write "
<tr>
  <td>&nbsp;</td>
  <td>$ha_city, $ha_state $ha_postal_code</td>"

if { [info exists ha_country_code] && $ha_country_code != "" && $ha_country_code != "us"} {
#    set ha_country_name [database_to_tcl_string $db "select country_name from ad_country_codes where iso='$country_code'"]
#    ns_write "&nbsp;&nbsp;&nbsp;&nbsp;$ha_country_name"

    set ha_country_name [database_to_tcl_string $db "
       select country_name from country_codes 
       where iso='$ha_country_code'"]
    ns_write "    $ha_country_name"

}

ns_write "
<tr>
  <th valign=top>Attending reason</th>
  <td>$attending_reason</td>
</tr>
<tr>
  <th valign=top>Heard from</th>
  <td>$where_heard</td>
</tr>
"

set needs_text "<tr><th valign=top>Needs</th><td><ul>"
if {$need_hotel_p == "t"} {
    append needs_text "<li>Needs Hotel"
}
if {$need_car_p == "t"} {
    append needs_text "<li>Needs a car"
}
if {$need_plane_p == "t"} {
    append needs_text "<li>Needs a plane ticket"
}

#ns_write "</td></tr>"

set selection [ns_db select $db "
select column_name, pretty_name,
sort_key
from events_event_fields
where event_id = $event_id
order by sort_key
"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    set table_name "event_"
    append table_name $event_id
    append table_name "_info"

    set sub_selection [ns_db 1row $db_sub "
    select $column_name 
    from 
    $table_name
    where user_id = $user_id"]
    
    set_variables_after_subquery
    
    ns_write "
    <tr>
     <th>$pretty_name</th>
     <td>[set $column_name]</td>
    </tr>"
}


append needs_text "</ul></table>"

ns_write $needs_text

if { [info exists comments] && $comments != ""} {
    ns_write "
    <tr>
     <td colspan=2>
     <h3>Comments</h3>
     <pre>$comments</pre>
    "
}

ns_write "
</table>

<h2>Registration Maintenance</h2>

<ul>
"

if {$reg_state == "pending" || $reg_state == "waiting"} {
    ns_write "<li>
    <a href=\"reg-approve.tcl?reg_id=$reg_id\">Approve Registration</a>
    |
    <a href=\"reg-cancel.tcl?reg_id=$reg_id\">Deny Registration</a>"
} elseif {$reg_state != "canceled"} {
    ns_write "<li>
    <a href=\"reg-cancel.tcl?reg_id=$reg_id\">Cancel Registration</a>"
} elseif {$reg_state == "canceled"} {
    ns_write "<li>
    <a href=\"reg-approve.tcl?reg_id=$reg_id\">Approve Registration</a>"
}


ns_write "
<li><a href=\"reg-comments.tcl?reg_id=$reg_id\">Add/Edit Comments</a>
</ul>

<hr width=50%>
<h2>All info in events_registrations table regarding registration # $reg_id</h2>
This is probably only worth looking at if there's a problem with the registration.
<p>
"

set selection [ns_db 0or1row $db "select *
from events_registrations
where reg_id = $reg_id"]

set_variables_after_query

ns_write "
<table>
<tr>
 <th>REG_ID 				  
 <td>$reg_id
<tr>
 <th>ORDER_ID
 <td>$order_id
<tr>
 <th>PRICE_ID
 <td>$price_id
<tr>
 <th>USER_ID
 <td>$user_id
<tr>
 <th>REG_STATE
 <td>$reg_state
<tr>
 <th>ORG 
 <td>$org
<tr>
 <th>TITLE_AT_ORG
 <td>$title_at_org
<tr>
 <th>ATTENDING_REASON				
 <td>$attending_reason
<tr>
 <th>WHERE_HEARD	
 <td>$where_heard				
<tr>
 <th>NEED_HOTEL_P
 <td>$need_hotel_p					
<tr>
 <th>NEED_CAR_P		
 <td>$need_car_p
<tr>
 <th>NEED_PLANE_P					
 <td>$need_plane_p
<tr>
 <th>COMMENTS		
 <td>$comments			
<tr>
 <th>REG_DATE	
 <td>$reg_date				
<tr>
 <th>SHIPPED_DATE					
 <td>$shipped_date
</table>
[ad_footer]
"











