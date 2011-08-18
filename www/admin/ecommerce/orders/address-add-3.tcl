# $Id: address-add-3.tcl,v 3.0.4.1 2000/04/28 15:08:43 carsten Exp $
set_the_usual_form_variables
# order_id, and either:
# attn, line1, line2, city, usps_abbrev, zip_code, phone, phone_time OR
# attn, line1, line2, city, full_state_name, zip_code, country_code, phone, phone_time

if { ![info exists QQusps_abbrev] } {
    set QQusps_abbrev ""
}
if { ![info exists QQfull_state_name] } {
    set QQfull_state_name ""
}
if { ![info exists QQcountry_code] } {
    set QQcountry_code "us"
}


# insert the address into ec_addresses, update the address in ec_orders

set db [ns_db gethandle]

ns_db dml $db "begin transaction"
set address_id [database_to_tcl_string $db "select ec_address_id_sequence.nextval from dual"]
set user_id [database_to_tcl_string $db "select user_id from ec_orders where order_id=$order_id"]

ns_db dml $db "insert into ec_addresses
(address_id, user_id, address_type, attn, line1, line2, city, usps_abbrev, full_state_name, zip_code, country_code, phone, phone_time)
values
($address_id, $user_id, 'shipping', '$QQattn', '$QQline1','$QQline2','$QQcity','$QQusps_abbrev','$QQfull_state_name','$QQzip_code','$QQcountry_code','$QQphone','$QQphone_time')
"
ns_db dml $db "update ec_orders set shipping_address=$address_id where order_id=$order_id"

ns_db dml $db "end transaction"

ad_returnredirect "one.tcl?[export_url_vars order_id]"