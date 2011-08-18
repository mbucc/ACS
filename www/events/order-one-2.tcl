set_the_usual_form_variables
# reg_id, event_id, price_id, bunch of user-entered stuff, order_id

#force ssl
#events_makesecure 
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

#check to see if this person has already registered
set selection [ns_db 0or1row $db "select 
reg_id, reg_date, reg_cancellable_p
from events_registrations r, events_prices p,
events_events e
where p.price_id = r.price_id
and p.event_id=$event_id
and r.user_id=$user_id
and e.event_id = $event_id
and reg_state <> 'canceled'
"]

if {![empty_string_p $selection]} {
    set_variables_after_query
    #he's already registered

    ns_db releasehandle $db
    ReturnHeaders
    ns_write "
    [ad_header "Already Registered"]
    <h2>Already Registered</h2>
    <a href=\"index.tcl\">[ad_system_name] events</a> 
    <hr>
    You have already registered for this event on 
    [util_AnsiDatetoPrettyDate $reg_date].
    <p>
    If you'd like, you may:
    <ul>
    <li><a href=\"order-check.tcl?[export_url_vars reg_id]\">Review your registration</a>
"
if {$reg_cancellable_p == "t"} {
    ns_write "
    <li><a href=\"order-cancel.tcl?[export_url_vars reg_id]\">Cancel your registration</a>"
}

ns_write "
    </ul>
    [ad_footer]"
    return;
}

# check for errors

set exception_count 0
set exception_text ""

if { ![info exists phone_number] || [string compare $phone_number ""] == 0 } {
    incr exception_count 
    append exception_text "<li>You forgot to enter your telephone number\n"
}

if { [info exists attending_reason] && [string length $attending_reason] > 4000 } {
    incr exception_count 
    append exception_text "<li>Please limit your reason for attending to 4000 characters.\n"
}


if { [info exists where_heard] && [string length $where_heard] > 4000 } {
    incr exception_count 
    append exception_text "<li>Please keep where you heard about this activity to less than 4000 characters.\n"
}

if { ![info exists line1] || [string compare $line1 ""] == 0 } {
    incr exception_count 
    append exception_text "<li>You forgot to enter your address\n"
}

if { ![info exists city] || [string compare $city ""] == 0 } {
    incr exception_count 
    append exception_text "<li>You forgot to enter your city\n"
}

if {$country_code == "us" && ![exists_and_not_null state]} {
    incr exception_count 
    append exception_text "<li>You forgot to enter your state\n"

}

#reallocate the handles now that we're done with ad_headers
ns_db releasehandle $db
set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]


set selection [ns_db 0or1row $db "select
a.short_name, 
a.activity_id,
e.display_after, 
e.start_time, 
e.end_time,
decode(e.max_people, null, '', e.max_people) as max_people,
e.venue_id,
v.description as venue_description,
v.venue_name
from events_events e, events_activities a, events_venues v
where e.event_id = $event_id 
and a.activity_id = e.activity_id
and v.venue_id = e.venue_id
"]


if {[empty_string_p $selection]} {
    incr exception_count
    append exception_text "<li>We couldn't find this event in our database."
} else {
    # got a row back from the db
    # set some Tcl vars for use below (bleah)
    set_variables_after_query
    set product_description "$short_name in 
    [events_pretty_venue $db $venue_id]
    from [util_AnsiDatetoPrettyDate $start_time] to
    [util_AnsiDatetoPrettyDate $end_time]"
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

#make sure these values exist
if {![exists_and_not_null need_hotel_p]} {
    set need_hotel_p "f"
}
if {![exists_and_not_null need_car_p]} {
    set need_car_p "f"
}
if {![exists_and_not_null need_plane_p]} {
    set need_plane_p "f"
}

set reg_state ""
#register the user
#if [catch {
    ns_db dml $db "begin transaction"

    #try to store the user's contact info
    ns_db dml $db "update users_contact
    set home_phone = '$QQphone_number',
    ha_line1 = '$QQline1',
    ha_line2 = '$QQline2', 
    ha_city = '$QQcity', 
    ha_state = '$state', 
    ha_postal_code = '$QQpostal_code', 
    ha_country_code = '$country_code'
    where user_id = $user_id
    "

    if {[ns_ora resultrows $db] == 0} {
	ns_db dml $db "insert into users_contact
	(user_id, home_phone, ha_line1, ha_line2, ha_city, ha_state, 
	ha_postal_code, ha_country_code)
	values
	($user_id, '$QQphone_number', '$QQline1', '$QQline2',
	'$QQcity', '$state','$QQpostal_code', 
	'$country_code')"
    }
       
    #create the order
    ns_db dml $db "insert into events_orders
    (order_id, user_id, ip_address)
    values
    ($order_id, $user_id, '[DoubleApos [ns_conn peeraddr]]')"

    #create the registration

    #need to lock the table for check registrations
    ns_db dml $db "lock table events_registrations in exclusive mode"
    
    #make sure there is room for registration
    set selection [ns_db 0or1row $db "select count(reg_id) as num_registered
    from events_registrations r, events_prices p
    where p.event_id = $event_id
    and r.price_id = p.price_id"]
    set_variables_after_query

    if {![empty_string_p $max_people] && $num_registered >= $max_people} {
	set reg_state "waiting"
    } else {
	set reg_state [database_to_tcl_string $db "select 
	decode(reg_needs_approval_p, 
	't', 'pending',
	'f', 'shipped',
	'shipped')
	from events_events where event_id = $event_id
	"]
    }

    ns_db dml $db "insert into events_registrations
    (reg_id, order_id, price_id, user_id, reg_state, org,
    title_at_org, attending_reason, where_heard, need_hotel_p,
    need_car_p, need_plane_p, reg_date)
    values
    ($reg_id, $order_id, $price_id, $user_id, '$reg_state',
    '$QQorg', '$QQtitle_at_org', '$QQattending_reason', 
    '$QQwhere_heard', '$need_hotel_p',
    '$need_car_p', '$need_plane_p', sysdate)"
    
    #store the custom fields
    set column_name_list [database_to_tcl_list $db "
    select column_name
    from events_event_fields
    where event_id = $event_id
    order by sort_key"]

    # doesn't need to be inside the loop
    set table_name "event_"
       append table_name $event_id; append table_name "_info"
    # prepare for the coming foreach { append ... } loop
    set columns_for_insert "("
    set values_for_insert "("

    foreach column_name $column_name_list {
        append columns_for_insert "$column_name, "
        append values_for_insert "'[set $column_name]', "
    }
    append columns_for_insert "user_id)"
    append values_for_insert "$user_id)"

    ns_db dml $db "insert into $table_name
    $columns_for_insert
    values
    $values_for_insert"


    #perhaps add the person to the event's user group and venue's user group
    if {$reg_state == "shipped"} {
	events_group_add_user $db $event_id $user_id
	#venues_group_add_user $db $venue_id $user_id
    }

    ns_db dml $db "end transaction"
#} err_msg] {
#    ad_return_error "Database Error" "We were unable to 
#    process you registration
#    <p>$err_msg" 
#    return
#}

#release the db handles for writing ad_header
ns_db releasehandle $db
ns_db releasehandle $db_sub

set whole_page "[ad_header "Thanks for Registering"]"

#get the db handle once more
set db [ns_db gethandle]

append whole_page "
<h2>Register</h2>
for <a href=\"activity.tcl?activity_id=$activity_id\"><i>$short_name</i></a>
in [events_pretty_venue $db $venue_id]<br>

<hr>
"

if {$reg_state == "waiting"} {
    append whole_page "
    Thank you for your registration.  Unfortunately, all spaces
    for this event were filled before you placed your registration.
    So, you have been placed on a waiting list.
    <p>
    We will e-mail you if you a space opens up for you.  
    Thank you for your interest in $short_name.
    "

} elseif {$reg_state == "pending"} {
    append whole_page "
    Thank you for your registration.  This event requires final approval
    for your registration from one of the event organizers.  You have
    been placed on a registration queue, and we will notify you shortly
    if your registration has been approved.  You will, in the mean time,
    receive an e-mail confirming that we have received your
    registration.
    <p>
    Thank you for your interest in $short_name.
    "
} else {
    append whole_page "
    Thank you for your registration--we have placed it in our
    database.
    $display_after
    <h3>Directions to $venue_name</h3>
    $venue_description"
}

#append whole_page "[ad_footer]"
#ns_conn close

# send email to the event's creator (high-volume sites will want to comment this out)
set creator_email [database_to_tcl_string $db "select
u.email from users u, events_events e
where e.event_id = $event_id
and u.user_id = e.creator_id"]

set user_email [database_to_tcl_string $db "select
email from users
where user_id=$user_id"]

set admin_subject "New reservation at [ad_parameter SystemURL]"
set admin_body "$user_email reserved a  space for \n\n   $product_description \n\nat [ad_parameter SystemURL]" 

if {$reg_state == "waiting"} {
    append admin_body "

    Since registration for this event is full, he has been placed on
    a waiting list."
} elseif {$reg_state == "pending"} {
    append admin_body "

    This event requires registrations to be approved.  Please come
    either approve or deny the request for registration:

    [ad_parameter SystemURL]/events/admin/reg-view.tcl?reg_id=$reg_id
    "
}


if [catch { ns_sendmail $creator_email $creator_email $admin_subject $admin_body} errmsg] {
    append whole_page "<p>failed sending email to $creator_email: $errmsg"
    ns_log Error "failed sending email to $creator_email: $errmsg"
} 

if {$reg_state == "waiting"} {
    set email_subject "Waiting list for $product_description"

    set email_body "
    You have been placed on the waiting list for
    
    $product_description
    
    We will e-mail you if a space opens up.
    
    If you would like to cancel your registration, you may visit
    [ad_parameter SystemURL]/events/order-cancel.tcl?[export_url_vars reg_id]
    "
} elseif {$reg_state == "shipped"} {	
    # send email to the registrant 
    
    set email_subject "directions to $product_description"
    
    set email_body "Your place is reserved in
    
    $product_description
    
    You'll get spammed with a reminder email a day or two before the 
    event.
    
    $display_after
    
    Venue description and directions:

    $venue_name\n

    $venue_description\n
    
    If you would like to cancel your order, you may visit
    [ad_parameter SystemURL]/events/order-cancel.tcl?[export_url_vars reg_id]
    "
} else {
    set email_subject "Registration Received"
    set email_body "We have received your request for registration for 

    $product_description

    We will notify you shortly if your registration is approved.
    
    If you would like to cancel your order, you may visit
    [ad_parameter SystemURL]/events/order-cancel.tcl?[export_url_vars reg_id]
    "
}
if [catch { ns_sendmail $user_email $creator_email $email_subject $email_body } errmsg] {
    append whole_page "<p>failed sending confirmation email to customer: $errmsg"
    ns_log Notice "failed sending confirmation email to customer: $errmsg"
} 

append whole_page "[ad_footer]"

ns_db releasehandle $db
ReturnHeaders
ns_write $whole_page
