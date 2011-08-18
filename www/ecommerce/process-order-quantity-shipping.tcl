# $Id: process-order-quantity-shipping.tcl,v 3.1.2.1 2000/04/28 15:10:02 carsten Exp $
# updates quantities, sets the shipping method,
# and finalizes the prices (inserts them into ec_items)

set_form_variables 0
# possibly quantity([list $product_id $color_choice $size_choice $style_choide])
# for each product_id w/color, size, style in the order
# (if this is the first time cycling through this script, in
# which case the quantities will be passed to shopping-cart-
# quantities-change.tcl and then all variables except the quantity
# array will be passed back to this script

# possibly shipping_method, if express shipping is available
# possibly usca_p

ec_redirect_to_https_if_possible_and_necessary

if {[info exists quantity]} {
    set arraynames [array names quantity]
    set fullarraynames [list]
    foreach arrayname $arraynames {
	lappend fullarraynames "quantity($arrayname)"
    }
    set return_url "process-order-quantity-shipping.tcl?[export_url_vars creditcard_id creditcard_number creditcard_type creditcard_expire_1 creditcard_expire_2 billing_zip_code shipping_method]"
    ad_returnredirect "shopping-cart-quantities-change.tcl?[export_url_vars return_url]&[eval export_url_vars $fullarraynames]"
    return
}

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {

    set form [ns_conn form]
    if { ![empty_string_p $form] } {
        set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    } else {
        set return_url "[ns_conn url]"
    }

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# user sessions:
# 1. get user_session_id from cookie
# 2. if user has no session (i.e. user_session_id=0), attempt to set it if it hasn't been
#    attempted before
# 3. if it has been attempted before, give them message that we can't do shopping carts
#    without cookies

set user_session_id [ec_get_user_session_id]

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]
ec_create_new_session_if_necessary [ec_export_entire_form_as_url_vars_maybe]
# type3

ec_log_user_as_user_id_for_this_session

# make sure they have an in_basket order, otherwise they've probably
# gotten here by pushing Back, so return them to index.tcl

set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_session_id=$user_session_id and order_state='in_basket'"]

if { [empty_string_p $order_id] } {
    # then they probably got here by pushing "Back", so just redirect them
    # to index.tcl
    ad_returnredirect index.tcl
    return
}

# make sure there's something in their shopping cart, otherwise
# redirect them to their shopping cart which will tell them
# that it's empty.

if { [database_to_tcl_string $db "select count(*) from ec_items where order_id=$order_id"] == 0 } {
    ad_returnredirect shopping-cart.tcl
    return
}

# make sure the order belongs to this user_id, otherwise they managed to skip past checkout.tcl, or
# they messed w/their user_session_id cookie
set order_owner [database_to_tcl_string $db "select user_id from ec_orders where order_id=$order_id"]

if { $order_owner != $user_id } {
    ad_returnredirect checkout.tcl
    return
}

# make sure there is an address for this order, otherwise they've probably
# gotten here via url surgery, so redirect them to checkout.tcl

set address_id [database_to_tcl_string_or_null $db "select shipping_address from ec_orders where order_id=$order_id"]
if { [empty_string_p $address_id] } {
    ad_returnredirect checkout.tcl
    return
}

if { ![info exists shipping_method] } {
    set shipping_method "standard"
}

# everything is ok now; the user has a non-empty in_basket order and an
# address associated with it, so now update shipping method


# 1. update the shipping method
ns_db dml $db "update ec_orders set shipping_method='[DoubleApos $shipping_method]' where order_id=$order_id"

# 2. put the prices into ec_items

# set some things to use as arguments when setting prices
if { [ad_parameter UserClassApproveP ecommerce] } {
    set additional_user_class_restriction "and user_class_approved_p = 't'"
} else {
    set additional_user_class_restriction "and (user_class_approved_p is null or user_class_approved_p='t')"
}
set user_class_id_list [database_to_tcl_list $db "select user_class_id from ec_user_class_user_map where user_id='$user_id' $additional_user_class_restriction"]
set selection [ns_db 1row $db "select default_shipping_per_item, weight_shipping_cost from ec_admin_settings"]
set_variables_after_query
set selection [ns_db 1row $db "select add_exp_amount_per_item, add_exp_amount_by_weight from ec_admin_settings"]
set_variables_after_query
set usps_abbrev [database_to_tcl_string $db "select usps_abbrev from ec_addresses where address_id=$address_id"]
if { ![empty_string_p $usps_abbrev] } {
    set selection [ns_db 0or1row $db "select tax_rate, shipping_p from ec_sales_tax_by_state where usps_abbrev='$usps_abbrev'"]
    if { ![empty_string_p $selection] } {
	set_variables_after_query
    } else {
	set tax_rate 0
	set shipping_p f
    }
} else {
    set tax_rate 0
    set shipping_p f
}

# set selection [ns_db select $db "select item_id, product_id
# from ec_items
# where order_id=$order_id"]

set selection [ns_db select $db "select i.item_id, i.product_id, u.offer_code
from ec_items i,
(select * from ec_user_session_offer_codes usoc where usoc.user_session_id=$user_session_id) u
where i.product_id=u.product_id(+)
and i.order_id=$order_id"]

# these will be updated as we loop through the items
set total_item_shipping_tax 0
set total_item_price_tax 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    set everything [ec_price_price_name_shipping_price_tax_shipping_tax_for_one_item $db_sub $product_id $offer_code $item_id $order_id $shipping_method $user_class_id_list $default_shipping_per_item $weight_shipping_cost $add_exp_amount_per_item $add_exp_amount_by_weight $tax_rate $shipping_p]

    set total_item_shipping_tax [expr $total_item_shipping_tax + [lindex $everything 4]]
    set total_item_price_tax [expr $total_item_price_tax + [lindex $everything 3]]

    ns_db dml $db_sub "update ec_items set price_charged=round([lindex $everything 0],2), price_name='[DoubleApos [lindex $everything 1]]', shipping_charged=round([lindex $everything 2],2), price_tax_charged=round([lindex $everything 3],2), shipping_tax_charged=round([lindex $everything 4],2) where item_id=$item_id"
}


# 3. Determine base shipping cost & put it into ec_orders


set order_shipping_cost [database_to_tcl_string $db "select nvl(base_shipping_cost,0) from ec_admin_settings"]

# add on the extra base cost for express shipping, if appropriate
if { $shipping_method == "express" } {
    set add_exp_base_shipping_cost [database_to_tcl_string $db "select nvl(add_exp_base_shipping_cost,0) from ec_admin_settings"]
    set order_shipping_cost [expr $order_shipping_cost + $add_exp_base_shipping_cost]
}

set tax_on_order_shipping_cost [database_to_tcl_string $db "select ec_tax(0,$order_shipping_cost,$order_id) from dual"]

ns_db dml $db "update ec_orders set shipping_charged=round($order_shipping_cost,2), shipping_tax_charged=round($tax_on_order_shipping_cost,2) where order_id=$order_id"

ad_returnredirect payment.tcl
