# $Id: process-payment.tcl,v 3.1.2.1 2000/04/28 15:10:02 carsten Exp $
# puts in the credit card data
set_form_variables 0
# creditcard_number, creditcard_type, creditcard_expire_1,
# creditcard_expire_2, billing_zip_code

# possibly creditcard_id if they want to use a previous credit
# card, but if there's anything in creditcard_number, that will
# override the selection of a past credit card

# possibly usca_p

ec_redirect_to_https_if_possible_and_necessary

if { [info exists creditcard_number] } {
    # get rid of spaces and dashes
    regsub -all -- "-" $creditcard_number "" creditcard_number
    regsub -all " " $creditcard_number "" creditcard_number
}


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

# make sure there is a shipping method for this order, otherwise they've probably
# gotten here via url surgery, so redirect them to checkout-2.tcl

set shipping_method [database_to_tcl_string $db "select shipping_method from ec_orders where order_id=$order_id"]
if { [empty_string_p $shipping_method] } {
    ad_returnredirect checkout-2.tcl
    return
}


## now do error checking; It is required that either
# (a) their gift_certificate_balance covers the total order price, or
# (b) they've selected a previous credit card (and creditcard_number is null,
#     otherwise we assume they want to use a new credit card), or
# (c) *all* of the credit card information for a new card has been filled in

# we only want price and shipping from this (to determine whether gift_certificate_balance covers cost)
set price_shipping_gift_certificate_and_tax [ec_price_shipping_gift_certificate_and_tax_in_an_order $db $order_id]

set order_total_price_pre_gift_certificate [expr [lindex $price_shipping_gift_certificate_and_tax 0] + [lindex $price_shipping_gift_certificate_and_tax 1]]

set gift_certificate_balance [database_to_tcl_string $db "select ec_gift_certificate_balance($user_id) from dual"]


if { $gift_certificate_balance >= $order_total_price_pre_gift_certificate } {
    set gift_certificate_covers_cost_p "t"
} else {
    set gift_certificate_covers_cost_p "f"
}

if { $gift_certificate_covers_cost_p == "f" } {
    
    if { ![info exists creditcard_id] || ([info exists creditcard_number] && ![empty_string_p $creditcard_number]) } {
	if { ![info exists creditcard_number] || [empty_string_p $creditcard_number] } {
	    # then they haven't selected a previous credit card nor have they entered
	    # new credit card info
	    ad_return_complaint 1 "<li> You forgot to specify which credit card you'd like to use."
	    return
	} else {
	    # then they are using a new credit card and we just have to check that they
	    # got it all right
	    
	    set exception_count 0
	    set exception_text ""
	    
	    if { [regexp {[^0-9]} $creditcard_number] } {
		# I've already removed spaces and dashes, so only numbers should remain
		incr exception_count
		append exception_text "<li> Your credit card number contains invalid characters."
	    }
	    	    
	    if { ![info exists creditcard_type] || [empty_string_p $creditcard_type] } {
		incr exception_count
		append exception_text "<li> You forgot to enter your credit card type."
	    }
	    
	    # make sure the credit card type is right & that it has the right number
	    # of digits
	    set additional_count_and_text [ec_creditcard_precheck $creditcard_number $creditcard_type]
	    
	    set exception_count [expr $exception_count + [lindex $additional_count_and_text 0]]
	    append exception_text [lindex $additional_count_and_text 1]
	    
	    if { ![info exists creditcard_expire_1] || [empty_string_p $creditcard_expire_1] || ![info exists creditcard_expire_2] || [empty_string_p $creditcard_expire_2] } {
		incr exception_count
		append exception_text "<li> Please enter your full credit card expiration date (month and year)"
	    }
	    
	    if { $exception_count > 0 } {
		ad_return_complaint $exception_count $exception_text
		return
	    }
	}
	
    } else {
	# they're using an old credit card, although we should make sure they didn't
	# submit to us someone else's creditcard_id or a blank creditcard_id
	if { [empty_string_p $creditcard_id] } {
	    # probably form surgery
	    ad_returnredirect checkout-2.tcl
	    return
	}
	set creditcard_owner [database_to_tcl_string_or_null $db "select user_id from ec_creditcards where creditcard_id=$creditcard_id"]
	if { $user_id != $creditcard_owner } {
	    # probably form surgery
	    ad_returnredirect checkout-2.tcl
	    return
	}
    }
}

# everything is ok now; the user has a non-empty in_basket order and an
# address associated with it, so now insert credit card info if needed

ns_db dml $db "begin transaction"

# If gift_certificate doesn't cover cost, either insert or update credit card

if { $gift_certificate_covers_cost_p == "f" } {
    if { ![info exists creditcard_number] || [empty_string_p $creditcard_number] } {
	# using pre-existing credit card
	ns_db dml $db "update ec_orders set creditcard_id=$creditcard_id where order_id=$order_id"
    } else {
	# using new credit card
	set creditcard_id [database_to_tcl_string $db "select ec_creditcard_id_sequence.nextval from dual"]
	ns_db dml $db "insert into ec_creditcards
	(creditcard_id, user_id, creditcard_number, creditcard_last_four, creditcard_type, creditcard_expire, billing_zip_code)
	values
	($creditcard_id, $user_id, '$creditcard_number', '[string range $creditcard_number [expr [string length $creditcard_number] -4] [expr [string length $creditcard_number] -1]]', '[DoubleApos $creditcard_type]','$creditcard_expire_1/$creditcard_expire_2','[DoubleApos $billing_zip_code]')
	"
	ns_db dml $db "update ec_orders set creditcard_id=$creditcard_id where order_id=$order_id"
    }
} else {
    # make creditcard_id be null (which it might not be if this isn't their first
    # time along this path)
    ns_db dml $db "update ec_orders set creditcard_id=null where order_id=$order_id"
}

ns_db dml $db "end transaction"

ad_returnredirect checkout-3.tcl