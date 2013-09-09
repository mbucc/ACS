#  www/ecommerce/shipping-address-2.tcl
ad_page_contract {
  @param attn
    @param line1
    @param line2:optional
    @param city
    @param usps_abbrev
    @param zip_code
    @param phone
    @param phone_time:optional
  @author
  @creation-date
  @cvs-id shipping-address-2.tcl,v 3.2.6.7 2000/08/18 21:46:35 stevenp Exp
} {
    attn
    line1
    line2:optional
    city
    usps_abbrev
    zip_code
    phone
    phone_time:optional
}


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
    
    set return_url "[ad_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register?[export_url_vars return_url]"
    return
}

# make sure they have an in_basket order, otherwise they've probably
# gotten here by pushing Back, so return them to index.tcl

set user_session_id [ec_get_user_session_id]



set order_id [db_string get_order_id "select order_id from ec_orders where user_session_id=:user_session_id and order_state='in_basket'" -default ""]

if { [empty_string_p $order_id] } {
    # then they probably got here by pushing "Back", so just redirect them
    # to index.tcl
    ad_returnredirect index.tcl
    return
}

set address_id [db_string get_new_address_id_from_seq "select ec_address_id_sequence.nextval from dual"]

db_transaction {

    db_dml insert_new_address "insert into ec_addresses
    (address_id, user_id, address_type, attn, line1, line2, city, usps_abbrev, zip_code, country_code, phone, phone_time)
    values
    (:address_id, :user_id, 'shipping', :attn, :line1,:line2,:city,:usps_abbrev,:zip_code,'us',:phone,:phone_time)
    "

    db_dml set_shipping_on_order "update ec_orders set shipping_address=:address_id where order_id=:order_id"

}
db_release_unused_handles
if { [ad_ssl_available_p] } {
    ad_returnredirect "https://[ns_config ns/server/[ns_info server]/module/nsssl Hostname]/ecommerce/checkout-2.tcl"
} else {
    ad_returnredirect "http://[ns_config ns/server/[ns_info server]/module/nssock Hostname]/ecommerce/checkout-2.tcl"
}
