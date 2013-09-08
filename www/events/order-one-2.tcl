# File: /events/order-one-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose: To let users order one event. (follows order-one.tcl)
#
# TODO:  change custom-field textentry so that
#        non-clob fields everywhere need to be checked for [commands] .
#        please don't let the user execute arbitrary tcl code.
#####
 
# event_id, price_id
# a bunch of user-entered stuff 

ad_page_contract {
    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-one-2.tcl,v 3.33.2.6 2000/07/24 04:30:21 bquinn Exp
} {
    {event_id:integer,notnull}
    {price_id:integer,notnull}
    {phone_number:notnull}
    {attending_reason:trim [db_null]}
    {org:trim [db_null]}
    {title_at_org:trim [db_null]}
    {where_heard:trim [db_null]}
    {need_hotel_p "f"}
    {need_car_p "f"}
    {need_pane_p "f"}
    {line1:trim,notnull}
    {line2:trim,optional [db_null]}
    {city:trim,notnull}
    {state:optional [db_null]}
    {postal_code:trim,notnull}
    {country_code:notnull}    
    {customfield:array,optional}
}

#force ssl
#events_makesecure 

#make sure that the price_id matches the event_id
set price_check [db_string evnt_sel_price "select
count(*)
from events_prices
where price_id = :price_id
and event_id = :event_id"]

if {!$price_check} {
    ad_return_warning "Price Does Not Match Event" "The Price
    ID that came in to this page does not match
    the event for which you are trying to register."
    return
}

set user_id [ad_maybe_redirect_for_registration]

set table_name [events_helper_table_name $event_id]

#check to see if this person has already registered
set reg_check [db_0or1row evnt_regcheck_sel "select 
reg_id, reg_date, reg_cancellable_p, reg_state
from events_registrations r, events_prices p, events_events e
where p.price_id = r.price_id
and p.event_id=:event_id
and r.user_id=:user_id
and e.event_id = :event_id
and reg_state <> 'canceled'
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

# check for errors

set exception_count 0
set exception_text ""

page_validation {
    set err_msg ""
    if { ![exists_and_not_null phone_number] } {
	append err_msg "<li>You forgot to enter your telephone number\n"
    }

    if { [info exists phone_number] && [string length $phone_number] > 100 } {
	append err_msg "<li>Your phone number cannot exceed 100
	characters\n"
    }

    if { [info exists attending_reason] && [string length $attending_reason] > 4000 } {
	append err_msg "<li>Please limit your reason for attending to 4000 characters.\n"
    }

    if { [info exists where_heard] && [string length $where_heard] > 4000 } {
	append err_msg "<li>Please keep where you heard about this activity to less than 4000 characters.\n"
    }

    if { ![exists_and_not_null line1] } {
	append err_msg "<li>You forgot to enter your address\n"
    }

    if { [info exists line1] && [string length $line1] > 80 } {
	append err_msg "<li>Line 1 of your address cannot exceed 80
	characters\n"
    }

    if { [info exists line2] && [string length $line2] > 80 } {
	append err_msg "<li>Line 2 of your address cannot exceed 80
	characters\n"
    }

    if { ![exists_and_not_null city] } {
	append err_msg "<li>You forgot to enter your city\n"
    }

    if { [info exists city] && [string length $city] > 80 } {
	append err_msg "<li>Your city cannot exceed 80
	characters\n"
    }

    if {$country_code == "us" && ![exists_and_not_null state]} {
	append err_msg "<li>You forgot to enter your state\n"
    }

    if { ![exists_and_not_null postal_code] } {
	append err_msg "<li>You forgot to enter your postal code\n"
    }

    if { [info exists postal_code] && [string length $postal_code] > 80 } {
	append err_msg "<li>Your postal code cannot exceed 80
	characters\n"
    }

    if { [info exists title_at_org] && [string length $title_at_org] > 500 } {
	append err_msg "<li>Please limit your title to 500 characters\n"
    }

    if { [info exists org] && [string length $org] > 500 } {
	append err_msg "<li>Please limit your organization name
	to 500 characters\n"
    }

    if {![empty_string_p $err_msg]} {
	error $err_msg
    }

}
#generate the reg_id and order_id
#we shouldn't need to worry about double-submissions because
#we are checking above to make sure that the user hasn't
#already registered for this event
set reg_id [db_string sel_reg_id_seq "select events_reg_id_sequence.nextval from dual"]
set order_id [db_string sel_order_id_seq "select events_orders_id_sequence.nextval from dual"]


set event_check [db_0or1row sel_check_evnt "select
    a.short_name, a.activity_id,
    e.display_after, e.start_time, e.end_time,
    to_char(e.start_time, 'fmHH:fmMI AM') as pretty_start_time,
    to_char(e.end_time, 'fmHH:fmMI AM') as pretty_end_time,
    decode(e.max_people, null, '', e.max_people) as max_people,
    e.venue_id,
    v.description as venue_description, v.venue_name
  from events_events e, events_activities a, events_venues v
 where  e.event_id = :event_id 
   and  a.activity_id = e.activity_id
   and  v.venue_id = e.venue_id
"]

if {!$event_check} {
    db_release_unused_handles
    ad_return_warning "Could Not Find Event" "We couldn't find 
    this event in our database."
    return
} else {
    # got a row back from the db
    set product_description "$short_name from [util_AnsiDatetoPrettyDate $start_time] $pretty_start_time to [util_AnsiDatetoPrettyDate $end_time] $pretty_end_time"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

#make sure these values exist
if {![exists_and_not_null need_hotel_p]} { set need_hotel_p "f" }
if {![exists_and_not_null need_car_p]}    { set need_car_p "f" }
if {![exists_and_not_null need_plane_p]} { set need_plane_p "f" }

set reg_state ""
# register the user
# TODO: catch this dml query with 'if [catch {... '
db_transaction {

#try to store the user's contact info
db_dml update_contact "update users_contact
set home_phone = :phone_number,
ha_line1 = :line1,
ha_line2 = :line2, 
ha_city = :city, 
ha_state = :state, 
ha_postal_code = :postal_code, 
ha_country_code = :country_code
where  user_id = :user_id
" 

if {[db_resultrows] == 0} {
    db_dml insert_contact "insert into users_contact
    (user_id, home_phone, ha_line1, ha_line2, ha_city, ha_state, 
    ha_postal_code, ha_country_code)
    values
    (:user_id, :phone_number, :line1, :line2,
    :city, :state,:postal_code, 
    :country_code)" 
}

set ip_address [ns_conn peeraddr]

#create the order
db_dml unused "insert into events_orders
(order_id, user_id, ip_address)
values
(:order_id, :user_id, :ip_address)" 

#create the registration

#need to lock the table for check registrations
db_dml unused "lock table events_registrations in exclusive mode"

#make sure there is room for registration
set num_registered [db_string check_reg_num "
select count(reg_id) as num_registered
from events_reg_shipped r, events_prices p
where  p.event_id = :event_id
and r.price_id = p.price_id"]

if {![empty_string_p $max_people] && $num_registered >= $max_people} {
    set reg_state "waiting"
} else {
    set reg_state [db_string evnt_get_reg_state "select 
    decode(reg_needs_approval_p,'t', 
    'pending','f','shipped','shipped')
    from events_events where event_id = :event_id
    "]
}

db_dml evnt_reg_insert "insert into events_registrations
(reg_id, order_id, price_id, user_id, reg_state, org,
title_at_org, attending_reason, where_heard, need_hotel_p,
need_car_p, need_plane_p, reg_date)
values
(:reg_id, :order_id, :price_id, :user_id, :reg_state,
:org, :title_at_org, :attending_reason, 
:where_heard, :need_hotel_p,
:need_car_p, :need_plane_p, sysdate)"

# store the custom fields.
# here c_n_l_l is a list of (c_n, p_n, c_a_t) triples.

#The customfields are passed to this page in the array customfield(column_name)
set column_name_list_list [db_list_of_lists evnt_get_custom_fields "
select column_name,
pretty_name, column_actual_type,
'customfield(' || column_name || ')' as array_column_name
from events_event_fields
where event_id = :event_id
order by sort_key"]

set table_name [events_helper_table_name $event_id]

# prepare for the coming foreach { append ... } loop
set columns_for_insert ""
set values_for_insert  ""

set clob_count 0 
set clob_names ""; set clob_vars ""; set clob_values "";

foreach column_name_list $column_name_list_list {
    set column_name [lindex $column_name_list 0] 
    set pretty_name [lindex $column_name_list 1] 
    set column_type [lindex $column_name_list 2]
    set array_column_name [lindex $column_name_list 3]
    if {[exists_and_not_null $array_column_name]} {
	set column_value [set $array_column_name]
    }
    if { ![exists_and_not_null column_value] } {
	#set column_value "NULL"
	set column_value ""
    }

    #see if the column is a varchar and thus has a size limit
    if {[regexp {varchar([0-9]*)\((.*)\)} $column_type match type size]} {
	if {[string length $column_value] > $size} {
	    db_abort_transaction
	    db_release_unused_handles
	    ad_return_complaint 1 "
	    <li>Please limit your $pretty_name to $size characters.\n"
	    return
	}
    }	

    #check for naughty html
    if { ![empty_string_p [ad_check_for_naughty_html $column_value]] } {
	db_abort_transaction
	db_release_unused_handles
	ad_return_complaint 1 "[ad_check_for_naughty_html $column_value]\n"
	return
    }
   
    #a hack to let the eval statement handle quotes better
    regsub -all {\"} $column_value { \&quot } column_value
    
    if { [string compare $column_type "clob"] == 0 } { 
	incr clob_count	   
	lappend clob_names  $column_name
	lappend clob_values $column_value
	lappend clob_vars   ":$clob_count" 
	# empty clob is filled by the 'returning...' clause
	lappend columns_for_insert $column_name
	lappend values_for_insert "empty_clob()"
    } else {
	lappend columns_for_insert $column_name
	lappend values_for_insert "'[DoubleApos $column_value]'"
    }
    set column_value ""
}
lappend columns_for_insert "user_id"
lappend values_for_insert $user_id

set clob_update_cmd " db_dml update_info_table \"update $table_name
set "

#don't set this to the length plus 1 (accounting for user_id) because
#we don't want to update the user_id
set count [llength $column_name_list_list]
set i 0
while {$i < $count} {
    if {$i == [expr $count - 1]} {
	#don't need a comma on the last one
	append clob_update_cmd "\[lindex \$columns_for_insert $i\] = 
	\[lindex \$values_for_insert $i\] "
    } else {
	append clob_update_cmd "\[lindex \$columns_for_insert $i\] = 
	\[lindex \$values_for_insert $i\], "
    }
    
    incr i
}
append clob_update_cmd "where user_id = $user_id
returning  [join $clob_names ", "] 
into  [join $clob_vars  ", "]
\" -clobs [list \$clob_values]"

set columns_sql [join $columns_for_insert ", "]
set values_sql  [join $values_for_insert  ", "]

#delay evaluation of the variables until the eval statement
set clob_insert_cmd "db_dml insert_custom_fields \"insert into $table_name
(\$columns_sql)
values
(\$values_sql)
returning  [join $clob_names ", "] 
into  [join $clob_vars  ", "]
\" -clobs [list \$clob_values]"

if { $clob_count > 0 } {   
    #DEBUG STUFF
    #ReturnHeaders 
    #regsub -all {\\} $clob_insert_cmd "" clob_insert_check
    #ns_write "<pre>{[subst $clob_insert_check]}</pre><p>"
    #regsub -all {\\} $clob_update_cmd "" clob_update_check
    #ns_write "<pre>{[subst $clob_update_check]}</pre><p>"
    
    set update_check [db_string sel_update_check "select
    count(*) from $table_name
    where user_id = :user_id"]
    
    if {$update_check > 0} {
	regsub -all {\\} $clob_update_cmd "" clob_update_cmd
	set clob_update_cmd [subst $clob_update_cmd]
	eval $clob_update_cmd
    } else {
	regsub -all {\\} $clob_insert_cmd "" clob_insert_cmd
	set clob_insert_cmd [subst $clob_insert_cmd]
	eval $clob_insert_cmd
    }
} else {
    set update_cmd "update $table_name set "
    set i 0
    while {$i < [expr $count + 1]} {
	if {$i == $count} {
	    #don't need a comma on the last one
	    append update_cmd "[lindex $columns_for_insert $i] = 
	    [lindex $values_for_insert $i] "
	} else {
	    append update_cmd "[lindex $columns_for_insert $i] = 
	    [lindex $values_for_insert $i], "
	}
	
	incr i
    }
    append update_cmd " where user_id = $user_id"
    
    #try to update first--then try to insert	
    if {$i > 0} {
	db_dml evnt_update_cmd $update_cmd
	set resultrows_count [db_resultrows]
    } else {
	set resultrows_count 0
    }
    
    if {$resultrows_count == 0} {
	db_dml evnt_insert_cmd "insert into $table_name
	($columns_sql)  
	values
	($values_sql)"
    }
}

    #perhaps add the person to the event's user group and venue's user group
if {$reg_state == "shipped"} {
    events_group_add_user $event_id $user_id
    #venues_group_add_user $db $venue_id $user_id
}

}
#end db_transaction

#} err_msg] {
#    ad_return_error "Database Error" "We were unable to 
#    process you registration
#    <p>$err_msg" 
#    return
#}

set whole_page "[ad_header "Thanks for Registering"]"

append whole_page "
<h2>Register</h2>
for <a href=\"activity?activity_id=$activity_id\"><i>$short_name</i></a>
in [events_pretty_venue $venue_id]<br>

[ad_context_bar_ws [list "index.tcl" "Events"] "Register"]
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

## send email to the event's creator 
## (high-volume sites will want to comment this out)
#set creator_email [db_string unused "select
# 	u.email from users u, events_events e
#  where  e.event_id = $event_id
#    and  u.user_id = e.creator_id"]
set contact_email [db_string evnt_sel_contact_email "select u.email
from users u, event_info ei, events_events e
where e.event_id = :event_id
and ei.group_id = e.group_id
and u.user_id = ei.contact_user_id"]

set user_email [db_string evnt_sel_user_email "select
	email from users
  where  user_id=:user_id"]

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

if [catch { ns_sendmail $contact_email $contact_email $admin_subject $admin_body} errmsg] {
    append whole_page "<p>failed sending email to $contact_email: $errmsg"
    ns_log Error "failed sending email to $contact_email: $errmsg"
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
    set email_body "
      Your place is reserved in
    
    $product_description
    
    You'll get spammed with a reminder email a day or two before the 
    event.
    
    [util_striphtml $display_after]
    
    Venue description and directions:

    $venue_name\n
    [util_striphtml $venue_description]\n
    
    If you would like to cancel your order, you may visit
    [ad_parameter SystemURL]/events/order-cancel.tcl?[export_url_vars reg_id]
    "
} else {
    set email_subject "Registration Received"
    set email_body " 
      We have received your request for registration for 

    $product_description

    We will notify you shortly if your registration is approved.

    If you would like to cancel your order, you may visit
    [ad_parameter SystemURL]/events/order-cancel.tcl?[export_url_vars reg_id]
    "
}

append email_body "
Information for this event is located at 
[ad_parameter SystemURL]/events/event-info.tcl?[export_url_vars event_id]"

if [catch { ns_sendmail $user_email $contact_email $email_subject $email_body } errmsg] {
    append whole_page "<p>failed sending confirmation email to customer: $errmsg"
    ns_log Notice "failed sending confirmation email to customer: $errmsg"
} 

### clean up.

append whole_page "[ad_footer]"

db_release_unused_handles
doc_return 200 text/html $whole_page

##### File Over
