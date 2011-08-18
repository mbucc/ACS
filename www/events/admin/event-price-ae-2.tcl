#not supporting prices at this time
return

set user_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables
#event_id, maybe product_id, product_name, price, available_date, expire_date, price_id

set db [ns_db gethandle]

set exception_count 0
set exception_text ""

if { [ns_dbformvalue [ns_conn form] available_time datetime available_time_value] <= 0 } {
    incr exception_count
    append exception_text "<li>Strange... couldn't parse the available time.\n"
}

if { [ns_dbformvalue [ns_conn form] expire_time datetime expire_time_value] <= 0 } {
    incr exception_count
    append exception_text "<li>Strange... couldn't parse the expiration
time.\n"
}

if {![exists_and_not_null product_name]} {
    incr exception_count
    append exception_text "<li>Please enter a price description.\n"
}

if {![exists_and_not_null price]} {
    incr excpetion_count
    append exception_text "<li>Please enter a price.\n"
}

if {![valid_number_p $price]} {
    incr exception_count
    append exception_text "<li>Please enter a valid number for the price.\n"
}
    

#check the dates
set selection [ns_db 0or1row $db "select 1 from dual, events_events
where to_date('$available_time_value', 'YYYY-MM-DD HH24:MI:SS') <
to_date('$expire_time_value', 'YYYY-MM-DD HH24:MI:SS')
and
to_date('$expire_time_value', 'YYYY-MM-DD HH24:MI:SS') <=
end_time
and event_id = $event_id"]

if {[empty_string_p $selection]} {
    incr exception_count
    append exception_text "<li>
    Please make sure your avaiable time is before your
    expiration time and your expiration time no later than 
    your event's end time.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

#ns_db dml $db "begin transaction"

#ns_db dml $db "update ec_products
#set product_name = '$QQproduct_name',
#price = $price,
#last_modified = sysdate,
#last_modifying_user = $user_id,
#modified_ip_address = '[DoubleApos [ns_conn peeraddr]]',
#available_date = to_date('$available_time_value', 'YYYY-MM-DD HH24:MI:SS')
#where product_id = $product_id"

ns_db dml $db "update events_prices
set expire_date = to_date('$expire_time_value', 'YYYY-MM-DD HH24:MI:SS'),
available_date = to_date('$available_time_value', 'YYYY-MM-DD HH24:MI:SS'),
description='$QQproduct_name',
price = $price
where price_id = $price_id
"

if {[ns_ora resultrows $db] == 0} {
#    ns_db dml $db "insert into ec_products
#    (product_id, product_name, creation_date, price, available_date,
#    last_modified, last_modifying_user, modified_ip_address)
#    values
#    ($product_id, '$QQproduct_name', sysdate, $price,
#    to_date('$available_time_value', 'YYYY-MM-DD HH24:MI:SS'),
#    sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"
    
    ns_db dml $db "insert into events_prices
    (price_id, event_id, description, expire_date,
    available_date, price)
    values
    ($price_id, $event_id, '$QQproduct_name', 
    to_date('$expire_time_value', 'YYYY-MM-DD HH24:MI:SS'),
    to_date('$available_time_value', 'YYYY-MM-DD HH24:MI:SS'),
    $price)"
}

#ns_db dml $db "end transaction"

ns_db releasehandle $db
ad_returnredirect "event.tcl?[export_url_vars event_id]"
