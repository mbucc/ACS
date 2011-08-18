# $Id: payment.tcl,v 3.1.2.1 2000/04/28 15:10:02 carsten Exp $
# This script has to check whether the user has a gift_certificate that can cover the
# cost of the order and, if not, present credit card form

ec_redirect_to_https_if_possible_and_necessary

set_form_variables 0

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# make sure they have an in_basket order, otherwise they've probably
# gotten here by pushing Back, so return them to index.tcl

# user session tracking
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

# address_id should already be in the database for this order
# otherwise they've probably gotten here via url surgery, so redirect them
# to checkout.tcl

set address_id [database_to_tcl_string_or_null $db "select shipping_address from ec_orders where order_id=$order_id"]
if { [empty_string_p $address_id] } {
    ad_returnredirect checkout.tcl
    return
}

# everything is ok now; the user has a non-empty in_basket order and an
# address associated with it, so now get the other necessary information

if { [ad_ssl_available_p] } {
    set form_action "[ec_secure_url][ad_parameter EcommercePath ecommerce]process-payment.tcl"
} else {
    set form_action "[ec_insecure_url][ad_parameter EcommercePath ecommerce]process-payment.tcl"
}

# ec_order_cost returns price + shipping + tax - gift_certificate BUT no gift certificates have been applied to
# in_basket orders, so this just returns price + shipping + tax
set order_total_price_pre_gift_certificate [database_to_tcl_string $db "select ec_order_cost($order_id) from dual"]

# determine gift certificate amount
set user_gift_certificate_balance [database_to_tcl_string $db "select ec_gift_certificate_balance($user_id) from dual"]

# I know these variable names look kind of retarded, but I think they'll
# make things clearer for non-programmers editing the ADP templates:
set gift_certificate_covers_whole_order 0
set gift_certificate_covers_part_of_order 0
set customer_can_use_old_credit_cards 0

set show_creditcard_form_p "t"
if { $user_gift_certificate_balance >= $order_total_price_pre_gift_certificate } {
    set gift_certificate_covers_whole_order 1

    set show_creditcard_form_p "f"
    
} elseif { $user_gift_certificate_balance > 0 } {
    set gift_certificate_covers_part_of_order 1

    set certificate_amount [ec_pretty_price $user_gift_certificate_balance]
}

if { $show_creditcard_form_p == "t" } {
    
    set customer_can_use_old_credit_cards 0

    # see if the administrator lets customers reuse their credit cards
    if { [ad_parameter SaveCreditCardDataP ecommerce] } {
	# then see if we have any credit cards on file for this user
	# for this shipping address only (for security purposes)
	
	set selection [ns_db select $db "select c.creditcard_id, c.creditcard_type, c.creditcard_last_four, c.creditcard_expire
	from ec_creditcards c
	where c.user_id=$user_id
	and c.creditcard_number is not null
	and c.failed_p='f'
	and 0 < (select count(*) from ec_orders o where o.creditcard_id=c.creditcard_id and o.shipping_address=$address_id)
	order by c.creditcard_id desc"]
	
	set to_print_before_creditcards "<table>
	<tr><td></td><td><b>Card Type</b></td><td><b>Last 4 Digits</b></td><td><b>Expires</b></td></tr>"
	
	set card_counter 0
	set old_cards_to_choose_from ""
	while { [ns_db getrow $db $selection] } {
	    set_variables_after_query
	    if { $card_counter == 0 } {
		append old_cards_to_choose_from $to_print_before_creditcards
	    }
	    append old_cards_to_choose_from "<tr><td><input type=radio name=creditcard_id value=\"$creditcard_id\""
	    if { $card_counter == 0 } {
		append old_cards_to_choose_from " checked"
	    }
	    append old_cards_to_choose_from "></td><td>[ec_pretty_creditcard_type $creditcard_type]</td><td align=center>$creditcard_last_four</td><td align=right>$creditcard_expire</td></tr>\n
	    "
	    incr card_counter
	}
	if { $card_counter != 0 } {
	    set customer_can_use_old_credit_cards 1
	    append old_cards_to_choose_from "</table>
	    "
	}
    }
    
    set ec_creditcard_widget [ec_creditcard_widget]
    set ec_expires_widget "[ec_creditcard_expire_1_widget] [ec_creditcard_expire_2_widget]"
    set zip_code [database_to_tcl_string $db "select zip_code from ec_addresses where address_id=$address_id"]

}

ad_return_template