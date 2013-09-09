# events/admin/reg-view.tcl
# Owner: bryanche@arsdigita.com
# Purpose: To show an admin details of an event's registration, including
#    the specific entries in the event_registrations table, for debugging.
#####

ad_page_contract {
    Purpose: To show an admin details of an event's registration, including
    the specific entries in the event_registrations table, for debugging.

    @param reg_id the registration at which we're looking

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id reg-view.tcl,v 3.17.2.6 2000/09/22 01:37:40 kevin Exp
} {
    {reg_id:integer,notnull}
}

# prepare the page to be returned
set whole_page ""

set reg_check [db_0or1row sel_reg_info "select 
	u.user_id,
	e.event_id,
	r.reg_state, r.need_hotel_p, r.need_plane_p, r.need_car_p,
	to_char(r.reg_date,'YYYY-MM-DD HH24:MI:SS') as reg_date, 
	to_char(r.shipped_date,'YYYY-MM-DD HH24:MI:SS') as shipped_date, 
	u.first_names, u.last_name, u.email, uc.home_phone, 
	uc.ha_line1, uc.ha_line2, uc.ha_city, uc.ha_state, 
	uc.ha_postal_code, uc.ha_country_code,
	r.attending_reason, r.where_heard, r.comments
   from events_registrations r, events_events e,
        users u, users_contact uc, events_prices p
  where  r.reg_id = :reg_id
    and  p.price_id = r.price_id
    and  e.event_id = p.event_id
    and  u.user_id = r.user_id
    and  r.user_id = uc.user_id(+)
"]

if {!$reg_check} {
     
     doc_return  200 text/html "[ad_header "Could not find registration"]

    <h2>Could not find registration</h2> in [ad_system_name]
    [ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "Registration"]
    <hr>
    
    Registration $reg_id was not found in the database.
    
    [ad_footer]
    "
    return
}

#if {$canceled_p == "t"} {
#    set canceled_text "(canceled)"
#} else {
#    set canceled_text ""
#}

## some formatting magic
set event [events_pretty_event $event_id]
regsub -all " from " $event "<br>from " event

append whole_page "[ad_header "Registration # $reg_id ($reg_state)" ]"

append whole_page "
<h2>Registration # $reg_id ($reg_state)</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "order-history.tcl" "Order History"] "Registration"]
<hr>

<table width=100%>
<tr><td valign=top>

<h3>Event Information</h3>
$event

<h3>Registration Information</h3>
<table>
<tr>
 <th>Registration State</td>
"

if {$reg_state == "pending"} {
    append whole_page "<td><font color=red>$reg_state</font>"
} else {
    append whole_page "<td>$reg_state"
}

append whole_page "
<tr>
 <th>Registration Date</td>
 <td>$reg_date</td>

</table>

</td><td valign=top>

<h3>Customer Information</h3>

<table>
<tr>
 <th>Name</th>
 <td><a href=\"order-same-person?[export_url_vars user_id]\">$first_names $last_name</a></td>
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
    append whole_page "<tr><td>&nbsp;</td><td>$ha_line2</td>"
}

append whole_page "
<tr>
  <td>&nbsp;</td>
  <td>$ha_city, $ha_state $ha_postal_code</td>"

if { [info exists ha_country_code] && $ha_country_code != "" && $ha_country_code != "us"} {
#    set ha_country_name [db_string unused "select country_name from ad_country_codes where iso='$country_code'"]
#    append whole_page "&nbsp;&nbsp;&nbsp;&nbsp;$ha_country_name"

    set ha_country_name [db_string sel_country_name "
       select country_name from country_codes 
       where iso=:ha_country_code"]
    append whole_page "    $ha_country_name"

}

append whole_page "
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

#append whole_page "</td></tr>"

set table_name [events_helper_table_name $event_id]

db_foreach sel_cols "
  select column_name, pretty_name, sort_key, column_type
    from events_event_fields
   where event_id = :event_id
   order by sort_key
" {
    if {![db_0or1row sel_col_name "
    	select $column_name 
          from $table_name
    where user_id = :user_id"]} {
	set column_value ""
    } else {
	set column_value [set $column_name]
    }

    #change &quot back to a quotation mark
    if {[string compare $column_type "text"] == 0} {
	regsub -all {\&quot} $column_value {"} column_value
    }
    
    append whole_page "
    <tr valign=top>
     <th>$pretty_name</th>     
     <td>[ad_decode $column_type "text" "[util_convert_plaintext_to_html $column_value]" "$column_value"]</td>
    </tr>"
}

append needs_text "</ul></table>"

append whole_page $needs_text

if { [info exists comments] && $comments != ""} {
    append whole_page "
     <tr><td colspan=2><h3>Comments</h3> <pre>[spam_wrap_text $comments]</pre>
    "
}

append whole_page "
</table>

<h2>Registration Maintenance</h2>
<ul>
"

if {$reg_state == "pending" || $reg_state == "waiting"} {
    append whole_page "<li>
    <a href=\"reg-approve?reg_id=$reg_id\">Approve Registration</a>
    |
    <a href=\"reg-cancel?reg_id=$reg_id\">Deny Registration</a>
    "

    if {$reg_state == "pending"} {
	append whole_page " |
	<a href=\"reg-wait-list?reg_id=$reg_id\">Wait-List Registration</a>
	"
    }

    #don't select from users_spammable because we need this email to
    #go out
    set sql_post_select "select user_id, email, 'text/plain' as email_type
    from users
    where user_id = $user_id"
    set create_comment_p 1
    set msg_text "We need more information to process your registration for\n[events_pretty_event $event_id]\nPlease come to\n[ad_parameter SystemURL]/events/order-one.tcl?[export_url_vars event_id]\n"
    append whole_page " |
    <a href=\"spam/action-choose?[export_url_vars event_id sql_post_select msg_text create_comment_p]\">
    Request More Info</a>"
} elseif {$reg_state != "canceled"} {
    append whole_page "<li>
    <a href=\"reg-cancel?reg_id=$reg_id\">Cancel Registration</a>"
} elseif {$reg_state == "canceled"} {
    append whole_page "<li>
    <a href=\"reg-approve?reg_id=$reg_id\">Approve Registration</a>"
}

append whole_page "
<li><a href=\"reg-comments?reg_id=$reg_id\">Add/Edit Comments</a>
</ul>

<hr width=50%>
<h2>All info in events_registrations table regarding registration # $reg_id</h2>
This is probably only worth looking at if there's a problem with the registration.
<p>
"

db_1row sel_reg_all "select *
from events_registrations
where reg_id = :reg_id"

append whole_page "
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

## clean up, return page

db_release_unused_handles

doc_return  200 text/html $whole_page
##### EOF
