set user_id [ad_maybe_redirect_for_registration]
set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]



set_the_usual_form_variables
# event_id, activity_id, venue_id, display_after
# start_time, end_time (from date/time entry widgets), prodcut_id, price_id, price, reg_cancellable_p

set exception_text ""
set exception_count 0

#if {![valid_number_p $price]} {
#    append exception_text  "<li>You did not enter a valid number for the price"
#    incr exception_count
#}

if { [catch {ns_dbformvalue [ns_conn form] reg_deadline datetime reg_deadline_value} err_msg]} {
    incr exception_count
    append exception_text "<li>Strange... couldn't parse the registration deadline.\n"
}

if { [catch {ns_dbformvalue [ns_conn form] start_time datetime start_time_value} err_msg]} {
    incr exception_count
    append exception_text "<li>Strange... couldn't parse the start time.\n"
}

if { [catch {ns_dbformvalue [ns_conn form] end_time datetime end_time_value} err_msg]} {
    incr exception_count
    append exception_text "<li>Strange... couldn't parse the end time.\n"
}

if {[exists_and_not_null max_people]} {
    if {[catch {set max_people [validate_integer "max_people" $max_people]}]} {
	incr exception_count
	append exception_text "<li>You must enter a number for maximum capacity"
    }
} else {
    set max_people "null"
}


if { ![info exists display_after] || $display_after == "" } {
    incr exception_count
    append exception_text "<li>Please enter a message for people who register.\n"
}

#check the dates
set selection [ns_db 0or1row $db "select 1 from dual 
where to_date('$start_time_value', 'YYYY-MM-DD HH24:MI:SS') < 
to_date('$end_time_value', 'YYYY-MM-DD HH24:MI:SS')
and
to_date('$reg_deadline_value', 'YYYY-MM-DD HH24:MI:SS') <=
to_date('$start_time_value', 'YYYY-MM-DD HH24:MI:SS')

"]
if {[empty_string_p $selection]} {
    incr exception_count
    append exception_text "<li>Please make sure your start time is before your
    end time and your registration deadline is no later than your start time.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ns_db dml $db "begin transaction"

#create the user group for this event
set name [database_to_tcl_string $db "select short_name
from events_activities where activity_id = $activity_id"]
set location [events_pretty_venue $db $venue_id]
set group_id [events_group_create $db $name $start_time_value $location]


if {$group_id == 0} {
    ns_db dml $db "abort transaction"
    ad_return_error "Couldn't create group" "We were unable to create a user group for your new event."
    return
}

#make this user an administrator of the user group
ns_db dml $db "insert into user_group_map 
(group_id, user_id, role, mapping_user, mapping_ip_address) 
select $group_id, $user_id, 'administrator', 
$user_id, '[DoubleApos [ns_conn peeraddr]]'
from dual where not exists 
 (select user_id 
 from user_group_map 
 where group_id = $group_id and 
 user_id = $user_id)"

#create the event
ns_db dml $db "insert into events_events
(event_id, activity_id, venue_id, display_after,
max_people, av_note, refreshments_note, additional_note,
start_time, end_time, reg_deadline, reg_cancellable_p, group_id,
reg_needs_approval_p, creator_id
)
values
($event_id, $activity_id, $venue_id,  '$QQdisplay_after', 
$max_people, '$QQav_note', '$QQrefreshments_note',
'$QQadditional_note',
to_date('$start_time_value', 'YYYY-MM-DD HH24:MI:SS'), 
to_date('$end_time_value', 'YYYY-MM-DD HH24:MI:SS'),
to_date('$reg_deadline_value', 'YYYY-MM-DD HH24:MI:SS'),
'$reg_cancellable_p', $group_id, '$reg_needs_approval_p',
$user_id
)"

#create the ec product
#ns_db dml $db "insert into ec_products
#(product_id, product_name, creation_date, price, available_date,
#last_modified, last_modifying_user, modified_ip_address)
#values
#($product_id, 'Normal Price', sysdate, $price, sysdate,
#sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"

#create the event price
ns_db dml $db "insert into events_prices
(price_id, event_id, description, price, expire_date, available_date)
values
($price_id, $event_id, 'Normal Price', 0, 
to_date('$reg_deadline_value', 'YYYY-MM-DD HH24:MI:SS'),
sysdate)"

#create the event's fields table and add the default fields
#from the activity
set table_name [events_helper_table_name $event_id]
ns_db dml $db "create table $table_name (
user_id integer not null references users)"

set selection [ns_db select $db "select
column_name, pretty_name, column_type, column_actual_type,
column_extra, sort_key
from events_activity_fields
where activity_id = $activity_id"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_db dml $db_sub "insert into events_event_fields
    (event_id, column_name, pretty_name, column_type, column_actual_type,
    column_extra, sort_key)
    values
    ($event_id, '[DoubleApos $column_name]', '[DoubleApos $pretty_name]', 
    '[DoubleApos $column_type]', 
    '[DoubleApos $column_actual_type]',
    '[DoubleApos $column_extra]', $sort_key)"

    ns_db dml $db_sub "alter table $table_name
    add ($column_name $column_actual_type $column_extra)"
}
    
ns_db dml $db "end transaction"

ad_returnredirect "event.tcl?event_id=$event_id"

