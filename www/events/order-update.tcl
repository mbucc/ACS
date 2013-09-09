ad_page_contract {
    Prompts user about updating registration information

    @param reg_id the registration to update

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-update.tcl,v 3.6.2.3 2000/07/21 03:59:34 ron Exp
} {
    {reg_id:integer,notnull}
}


set user_id [ad_maybe_redirect_for_registration]

#get the person's registration info
set reg_check [db_0or1row evnt_check_reg "
select
r.reg_state, r.org, r.title_at_org, r.attending_reason, r.where_heard, 
r.attending_reason,
u.first_names || ' ' || u.last_name as user_name,
u.email, 
uc.ha_line1, uc.ha_line2, uc.ha_city, uc.ha_state,
uc.ha_postal_code, uc.ha_country_code,
uc.home_phone,
e.event_id, to_char(e.end_time, 'YYYY-MM-DD HH24:MI:SS') as end_time
from events_reg_not_canceled r, users u, users_contact uc,
events_events e, events_prices p
where r.reg_id = :reg_id
and r.user_id = :user_id
and u.user_id = :user_id
and uc.user_id = $user_id
and p.price_id = r.price_id
and e.event_id = p.event_id
"]

if {!$reg_check} {
    ad_return_warning "Registration Not Found" "Registration $reg_id
    was not found or does not belong to you."
    return
}

#see if this event is over
set event_end_check [db_0or1row event_over_check "
select '1_end' from dual
where to_date(:end_time, 'YYYY-MM-DD HH24:MI:SS') > sysdate"]
if {!$event_end_check} {
    ad_return_warning "Event is Over" "This event is already over.
    There is no need to update your registration information."
    return
}

append whole_page "
[ad_header "Update Registration"]
<h2>Update Registration for [events_pretty_event $event_id]</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] "Update Registration"]
<hr>
<form method=post action=\"order-update-2\">
[export_form_vars reg_id]

<h3>About You</h3>
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
 <td><input type=text name=org value=\"$org\" size=50>
<tr>
 <td valign=top>Title/Job Description
 <td><input type=text name=title_at_org value=\"$title_at_org\" size=50>
<tr>
 <td valign=top>Where did you hear<br>about this activity?<br>
 <td><input type=text name=where_heard value=\"$where_heard\" size=50>
<tr>
 <td valign=top>Reason for attending:<br>
 <td><textarea name=attending_reason cols=40 rows=5 wrap=soft>$attending_reason
 </textarea>
"

#get the name of the table holding the registration info 
set table_name [events_helper_table_name $event_id]

#get the user's custom reg info
db_foreach sel_custom_reg "
select column_name, pretty_name, column_type, column_actual_type, 
column_extra, sort_key
from events_event_fields
where event_id = :event_id
order by sort_key " {
    #get the value for this
    if { ![db_0or1row sel_col_value "select 
       $column_name 
       from $table_name
    where user_id = :user_id" ] } {
	set $column_name ""
    } elseif {[string compare [set $column_name] "NULL"] == 0} {
	#a hack to get rid of the "NULL" in the UI
	set $column_name ""
    }

    #a hack to get rid of the brackets around a clob
    if {[string compare [string tolower $column_actual_type] "clob"] == 0} {
	set end_index [expr [string length [set $column_name]] - 1]
	set clob_val [set $column_name]

	if {[string compare [string range $clob_val 0 0] "\{"] == 0 &&	[string compare [string range $clob_val $end_index $end_index] "\}"] == 0} {
	    set $column_name [join $clob_val " "]
	}
    }

    #make column_name into an array for ad_page_contract
    append whole_page "
    <tr><td>$pretty_name
    <td>[ad_user_group_type_field_form_element customfield.$column_name $column_type [set $column_name]]"
}

append whole_page "
</table>

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
<center> <input type=submit value=\"Update Registration Info\"> </center>
</form>
"

append whole_page "
[ad_footer]"


doc_return  200 text/html $whole_page