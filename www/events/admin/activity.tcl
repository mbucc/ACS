# /www/events/admin/activity.tcl

ad_page_contract {
    Displays a particular activity to an admin, with options
    for modifying the event.    
    
    @param activity_id the activity at which we're looking

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id activity.tcl,v 3.11.2.9 2000/09/22 01:37:35 kevin Exp
} {
    activity_id:integer,notnull
}

set admin_id [ad_maybe_redirect_for_registration]

#make sure the user is allowed to administrate this activity
set admin_ck [db_string evnt_activity_ck "select
1 as admin_ck
from user_group_map ugm, events_activities a
where a.group_id = ugm.group_id
and a.activity_id = :activity_id
and ugm.user_id = :admin_id
union
select 
1 as admin_ck
from events_activities a
where activity_id = :activity_id
and group_id is null
" -default 0]

if {!$admin_ck} {
    db_release_unused_handles
    ad_return_warning "Permission Denied" "You do not have
    permission to edit this activity"
    return
}

#activities.default_price,
db_1row activity_properties "
select a.short_name, 
       a.creator_id, 
       a.description, 
       a.detail_url,
       a.available_p,
       a.default_contact_user_id,
       ug.group_name,
       u.user_id,
       u.first_names || ' ' || u.last_name as creator
from   events_activities a, users u, user_groups ug
where  activity_id = :activity_id
and    u.user_id = a.creator_id
and    a.group_id = ug.group_id(+)"

if {![exists_and_not_null group_name]} {
    set group_name ""
}

if {[exists_and_not_null default_contact_user_id]} {
    set default_contact [db_string default_contact "select
    email from users where user_id = :default_contact_user_id"]
} else {
    set default_contact ""
}

set whole_page "
[ad_header $short_name]

<h2>$short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "activities.tcl" Activities] "Activity"]
<hr>

<h3>Events for this Activity</h3>
"

append whole_page "
<ul>
<li><a href=\"event-add?activity_id=$activity_id\">Add an Event</a>
<p>"


db_foreach activity_events "
select e.event_id, 
       v.city,
       decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location,
       e.start_time, count(reg_id) as n_orders 
from   events_events e, events_reg_not_canceled r, events_venues v,
       events_prices p, country_codes cc
where  e.activity_id = :activity_id 
and    p.price_id = r.price_id(+) 
and    e.event_id = p.event_id(+) 
and    v.venue_id = e.venue_id 
and    cc.iso = v.iso
group by e.event_id, v.city, v.iso, v.usps_abbrev, cc.country_name, 
         e.start_time 
order by start_time" {

    append whole_page "<li><a href=\"event?event_id=$event_id\">$city, $big_location</a> [util_AnsiDatetoPrettyDate $start_time]\n (registration: $n_orders)"

} if_no_rows {
    append whole_page "No events for this activity have been created.\n"
}

# ?
if {$available_p == "t"} {
    append whole_page "
    "
} 

append whole_page "
</ul>
<h3>Activity Description</h3>
<table>
<tr>
  <th valign=top>Name</th>
  <td valign=top>$short_name</td>
</tr>
<tr>
  <th valign=top>Creator</th>
  <td valign=top>$creator</td>
</tr>
<tr>
  <th valign=top>Default Contact Person</th>
  <td valign=top>$default_contact</td>
</tr>
<tr>
  <th valign=top>Owning Group</th>
  <td valign=top>$group_name</td>
</tr>
"

# Some unused ecommerce-related html
#<tr>
# <th valign=top>Default Price
# <td valign=top>$[util_commify_number $default_price]

append whole_page "
<tr>
 <th valign=top>URL
 <td valign=top>$detail_url
<tr>
  <th valign=top>Description</th>
  <td valign=top>$description</td>
</tr>
<tr>
  <th valign=top>Current or Discontinued</th>
"
if {[string compare $available_p "t"] == 0} {
    append whole_page "<td valign=top>Current</td>"
} else {
    append whole_page "<td valign=top>Discontinued</td>"
}

append whole_page "
</table>

<p>
<ul>
<li><a href=\"activity-edit?[export_url_vars activity_id]\">Edit Activity</a>
</ul>

<h3>Activity Custom Fields</h3>
 You may define default custom fields which you would like to
 collect from registrants for this activity type.
<p>
<table>
"

set number_of_fields [db_string number_of_fields "select count(*) from events_activity_fields where activity_id=:activity_id"]

set counter 0 
db_foreach custom_fields "
select column_name, pretty_name, column_type, column_actual_type,
       column_extra, sort_key
from   events_activity_fields
where  activity_id = :activity_id
order by sort_key" {
    incr counter 

    if { $counter == $number_of_fields } {
	append whole_page "
<tr>
 <td><ul><li>$column_name ($pretty_name), $column_actual_type ($column_type) $column_extra
 <td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"activity-field-add?activity_id=$activity_id&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"activity-field-delete?[export_url_vars activity_type column_name activity_id]\">delete</a>&nbsp;\]</font></ul>\n"
    } else {
	append whole_page "
<tr>
 <td><ul><li>$column_name ($pretty_name), $column_actual_type ($column_type) $column_extra
 <td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"activity-field-add?activity_id=$activity_id&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"activity-field-swap?activity_id=$activity_id&sort_key=$sort_key\">swap&nbsp;with&nbsp;next</a>&nbsp;|&nbsp;<a href=\"activity-field-delete?[export_url_vars activity_id column_name]\">delete</a>&nbsp;\]</font></ul>\n"
    }

} if_no_rows {

    append whole_page " 
<tr><td><ul><li>no custom fields currently collected</ul> 
"
}

append whole_page "
</table><p>
<ul><li><a href=\"activity-field-add?[export_url_vars activity_id]\">add a field</a>
</ul>
"

append whole_page "<h3>Organizer Roles</h3>\n 
You may create default organizer roles for this activity type.
<ul>"

#decode(public_role_p, 't', '(public role)', '') as public_role_p
db_foreach default_org_roles "
select role, 
       role_id, 
       decode(public_role_p, 't', ': (public role)', '') as public_role_p
from   events_activity_org_roles
where  activity_id = :activity_id
order by role " {
    append whole_page "<li><a href=\"organizer-role-ae?[export_url_vars role_id activity_id]\">$role</a> $public_role_p\n"

} if_no_rows {

    append whole_page "<li>There are no organizer roles for this activity"
}

append whole_page "
<p>
<li><a href=\"organizer-role-ae?[export_url_vars activity_id]\">Add a new organizer role</a>
</ul>

<h3>Accounting</h3>
<ul><li><a href=\"order-history-one-activity?activity_id=$activity_id\">View All Orders for this Activity</a>
</ul>

[ad_footer]"

## Clean up.



doc_return  200 text/html $whole_page

##### File Over
