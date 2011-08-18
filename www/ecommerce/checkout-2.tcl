# $Id: checkout-2.tcl,v 3.1.2.2 2000/04/28 15:09:59 carsten Exp $
set_form_variables 0
# possibly address_id, usca_p

ec_redirect_to_https_if_possible_and_necessary

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

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

ec_create_new_session_if_necessary [export_url_vars address_id]
# type5

# make sure they have an in_basket order, otherwise they've probably
# gotten here by pushing Back, so return them to index.tcl

set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_session_id=$user_session_id and order_state='in_basket'"]

if { [empty_string_p $order_id] } {
    # then they probably got here by pushing "Back", so just redirect them
    # to index.tcl

    ad_returnredirect index.tcl
    return
}

# make sure the order belongs to this user_id (why?  because before this point there was no
# personal information associated with the order (so it was fine to go by user_session_id), 
# but now there is, and we don't want someone messing with their user_session_id cookie and
# getting someone else's order)

set order_owner [database_to_tcl_string $db "select user_id from ec_orders where order_id=$order_id"]

if { $order_owner != $user_id } {
    # either they managed to skip past checkout.tcl, or they messed w/their user_session_id cookie

    ad_returnredirect checkout.tcl
    return
}

# make sure there's something in their shopping cart, otherwise
# redirect them to their shopping cart which will tell them
# that it's empty.

if { [database_to_tcl_string $db "select count(*) from ec_items where order_id=$order_id"] == 0 } {

    ad_returnredirect shopping-cart.tcl
    return
}

# either address_id should be a form variable, or it should already
# be in the database for this order

# make sure address_id, if it exists, belongs to them, otherwise 
# they've probably gotten here by form surgery, in which case send
# them back to checkout.tcl
# if it is theirs, put it into the database for this order

# if address_id doesn't exist, make sure there is an address for this order, 
# otherwise they've probably gotten here via url surgery, so redirect them
# to checkout.tcl

if { [info exists address_id] && ![empty_string_p $address_id] } {
    set n_this_address_id_for_this_user [database_to_tcl_string $db "select count(*) from ec_addresses where address_id=$address_id and user_id=$user_id"]
    if {$n_this_address_id_for_this_user == 0} {


	ad_returnredirect checkout.tcl
	return
    }
    # it checks out ok
    ns_db dml $db "update ec_orders set shipping_address=$address_id where order_id=$order_id"
} else {
    set address_id [database_to_tcl_string_or_null $db "select shipping_address from ec_orders where order_id=$order_id"]
    if { [empty_string_p $address_id] } {

	ad_returnredirect checkout.tcl
	return
    }
}

# everything is ok now; the user has a non-empty in_basket order and an
# address associated with it, so now get the other necessary information

if { [ad_ssl_available_p] } {
    set form_action "https://[ns_config ns/server/[ns_info server]/module/nsssl Hostname]/ecommerce/process-order-quantity-shipping.tcl"
} else {
    set form_action "http://[ns_config ns/server/[ns_info server]/module/nssock Hostname]/ecommerce/process-order-quantity-shipping.tcl"
}

set selection [ns_db select $db "select p.product_name, p.one_line_description, p.product_id, count(*) as quantity, u.offer_code, i.color_choice, i.size_choice, i.style_choice
from ec_orders o, ec_items i, ec_products p, 
(select * from ec_user_session_offer_codes usoc where usoc.user_session_id=$user_session_id) u
where i.product_id=p.product_id
and o.order_id=i.order_id
and p.product_id=u.product_id(+)
and o.user_session_id=$user_session_id and o.order_state='in_basket'
group by p.product_name, p.one_line_description, p.product_id, u.offer_code, i.color_choice, i.size_choice, i.style_choice"]

set rows_of_items ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    set option_list [list]
    if { ![empty_string_p $color_choice] } {
	lappend option_list "Color: $color_choice"
    }
    if { ![empty_string_p $size_choice] } {
	lappend option_list "Size: $size_choice"
    }
    if { ![empty_string_p $style_choice] } {
	lappend option_list "Style: $style_choice"
    }
    set options [join $option_list ", "]


    append rows_of_items "<tr>
    <td><input type=text name=\"quantity([list $product_id $color_choice $size_choice $style_choice])\" value=\"$quantity\" size=4 maxlength=4></td>
    <td><a href=\"product.tcl?product_id=$product_id\">$product_name</a>[ec_decode $options "" "" ", $options"]<br>
    [ec_price_line $db_sub $product_id $user_id $offer_code]</td>
    </tr>
    "
}

set shipping_options ""

if { [ad_parameter ExpressShippingP ecommerce] } {
    append shipping_options "<p>
    <b><li>Shipping method:</b>
    <p>
    <input type=radio name=shipping_method value=\"standard\" checked>Standard Shipping<br>
    <input type=radio name=shipping_method value=\"express\">Express
    <p>
    "
}

ad_return_template