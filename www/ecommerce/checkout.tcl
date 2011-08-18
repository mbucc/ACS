# $Id: checkout.tcl,v 3.1.2.1 2000/04/28 15:10:00 carsten Exp $
set_form_variables 0
# possibly usca_p

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# make sure they have an in_basket order, otherwise they've probably
# gotten here by pushing Back, so return them to index.tcl

set user_session_id [ec_get_user_session_id]

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]
ec_create_new_session_if_necessary
# type1

ec_log_user_as_user_id_for_this_session

set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_session_id=$user_session_id and order_state='in_basket'"]

if { [empty_string_p $order_id] } {
    # then they probably got here by pushing "Back", so just redirect them
    # to index.tcl
    ad_returnredirect index.tcl
    return
} else {
    ns_db dml $db "update ec_orders set user_id=$user_id where order_id=$order_id"
}

# see if there are any saved shipping addresses for this user

set selection [ns_db select $db "select address_id, attn, line1, line2, city, usps_abbrev, zip_code, phone, country_code, full_state_name, phone_time
from ec_addresses
where user_id=$user_id
and address_type='shipping'"]


set saved_addresses ""

set to_print_if_addresses_exist "<b>Please enter a shipping address.</b> You can select an address listed below as your shipping address or enter a new address.
"
if { [ad_parameter SaveCreditCardDataP ecommerce] } {
    append to_print_if_addresses_exist "<p>
If you select an address listed below, and have already used a credit card to pay for previous shipments to that address, you will be able to use that credit card without having to give us the credit card number again. 
"
}

set address_counter 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { $address_counter == 0 } {
	append saved_addresses "$to_print_if_addresses_exist
	<p>
	<table border=0 cellspacing=0 cellpadding=20>
	"
    }

    if { [ad_ssl_available_p] } {
	set address_link "https://[ns_config ns/server/[ns_info server]/module/nsssl Hostname]/ecommerce/checkout-2.tcl?[export_url_vars address_id]"
    } else {
	set address_link "http://[ns_config ns/server/[ns_info server]/module/nssock Hostname]/ecommerce/checkout-2.tcl?[export_url_vars address_id]"
    }

    append saved_addresses "
    <tr>
    <td>
    [ec_display_as_html [ec_pretty_mailing_address_from_args $db_sub $line1 $line2 $city $usps_abbrev $zip_code $country_code $full_state_name $attn $phone $phone_time]]
    </td>
    <td>
    <a href=\"$address_link\">\[use this address\]</a>
    </td>
    </tr>
    "
    
    incr address_counter
}

if { $address_counter != 0 } {
    append saved_addresses "</table>"
}

ad_return_template
