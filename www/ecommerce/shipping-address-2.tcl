# $Id: shipping-address-2.tcl,v 3.1.2.1 2000/04/28 15:10:02 carsten Exp $
set_the_usual_form_variables
# attn, line1, line2, city, usps_abbrev, zip_code, phone, phone_time

# attn, line1, city, usps_abbrev, zip_code, phone are mandatory

set possible_exception_list [list [list attn name] [list line1 address] [list city city] [list usps_abbrev state] [list zip_code "zip code"] [list phone "telephone number"]]

set exception_count 0
set exception_text ""

foreach possible_exception $possible_exception_list {
    if { ![info exists [lindex $possible_exception 0]] || [empty_string_p [set [lindex $possible_exception 0]]] } {
	incr exception_count
	append exception_text "<li>You forgot to enter your [lindex $possible_exception 1]."
    }
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# make sure they have an in_basket order, otherwise they've probably
# gotten here by pushing Back, so return them to index.tcl

set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]

set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_session_id=$user_session_id and order_state='in_basket'"]

if { [empty_string_p $order_id] } {
    # then they probably got here by pushing "Back", so just redirect them
    # to index.tcl
    ad_returnredirect index.tcl
    return
}

set address_id [database_to_tcl_string $db "select ec_address_id_sequence.nextval from dual"]

ns_db dml $db "begin transaction"

ns_db dml $db "insert into ec_addresses
(address_id, user_id, address_type, attn, line1, line2, city, usps_abbrev, zip_code, country_code, phone, phone_time)
values
($address_id, $user_id, 'shipping', '$QQattn', '$QQline1','$QQline2','$QQcity','$QQusps_abbrev','$QQzip_code','us','$QQphone','$QQphone_time')
"

ns_db dml $db "update ec_orders set shipping_address=$address_id where order_id=$order_id"

ns_db dml $db "end transaction"

if { [ad_ssl_available_p] } {
    ad_returnredirect "https://[ns_config ns/server/[ns_info server]/module/nsssl Hostname]/ecommerce/checkout-2.tcl"
} else {
    ad_returnredirect "http://[ns_config ns/server/[ns_info server]/module/nssock Hostname]/ecommerce/checkout-2.tcl"
}
