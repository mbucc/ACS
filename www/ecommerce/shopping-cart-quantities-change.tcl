# $Id: shopping-cart-quantities-change.tcl,v 3.1.2.1 2000/04/28 15:10:03 carsten Exp $
set_the_usual_form_variables
# quantity([list $product_id $color_choice $size_choice $style_choice]) for each of
# the products in the cart and possibly return_url (because both shopping-cart.tcl and 
# process-order-quantity-payment-shipping.tcl send quantities through this script

# find the user_session_id and the order_id and then the product_ids in this
# user's shopping basket

set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]

if { $user_session_id == 0 } {
    ns_return 200 text/html "[ad_header "No Cart Found"]<h2>No Shopping Cart Found</h2>
    <p>
    We could not find any shopping cart for you.  This may be because you have cookies 
    turned off on your browser.  Cookies are necessary in order to have a shopping cart
    system so that we can tell which items are yours.

    <p>
    <i>In Netscape 4.0, you can enable cookies from Edit -> Preferences -> Advanced. <br>

    In Microsoft Internet Explorer 4.0, you can enable cookies from View -> 
    Internet Options -> Advanced -> Security. </i>

    <p>

    [ec_continue_shopping_options $db]
    "
    return
}

set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where order_state='in_basket' and user_session_id=$user_session_id"]

# if order_id is null, this probably means that they got to this page by pushing back
# so just return them to their empty cart

if { [empty_string_p $order_id] } {
    ad_returnredirect "shopping-cart.tcl"
    return
}

set product_color_size_style_list [array names quantity]

# set product_id_list [database_to_tcl_list $db "select unique product_id from ec_items where order_id=$order_id"]

# # if product_id_list is empty, this probably means that they got to this page by pushing back
# # so just return them to their empty cart

# if { [llength $product_id_list] == 0 } {
#     ad_returnredirect "shopping-cart.tcl"
#     return
# }

# now for the kind of tricky part: determine the quantity of each product (w/same color,size,style)
# in this order in the ec_items table, compare it with quantity([list $product_id $color_choice $size_choice $style_choice]),
# and then either add or remove the appropriate number of rows in ec_items

set selection [ns_db select $db "select i.product_id, i.color_choice, i.size_choice, i.style_choice, count(*) as r_quantity
from ec_orders o, ec_items i
where o.order_id=i.order_id
and o.user_session_id=$user_session_id and o.order_state='in_basket'
group by i.product_id, i.color_choice, i.size_choice, i.style_choice"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set real_quantity([list $product_id $color_choice $size_choice $style_choice]) $r_quantity
}


ns_db dml $db "begin transaction"

foreach product_color_size_style $product_color_size_style_list {
    # quantity_to_add might be negative
    # also there are two special cases that may come about, for instace,
    # when a user pushes "Back" to get here after having altered their cart
    # (1) if quantity($product_id) exists but real_quantity($product_id)
    #     doesn't exist, then ignore it (we're going to miss that
    #     product_id anyway when looping through product_id_list)
    # (2) if real_quantity($product_id) exists but quantity($product_id)
    #     doesn't exist then quantity_to_add will be 0
    
    set product_id [lindex $product_color_size_style 0]
    set color_choice [lindex $product_color_size_style 1]
    set size_choice [lindex $product_color_size_style 2]
    set style_choice [lindex $product_color_size_style 3]

    if { [info exists quantity($product_color_size_style)] } {
	if { [regexp {[^0-9]} $quantity($product_color_size_style)] } {
	    # if the new quantity is non-numeric, just leave the quantity alone
	    set quantity_to_add 0
	} else {
	    # if real_quantity([list $product_id $color_choice $size_choice $style_choice])
	    # doesn't exist, that means that the products on the form don't correspond to
	    # the products in the database, which implies that they had submitted an
	    # out-of-date shopping-cart.tcl form, so just redirect them to shopping-cart.tcl
	    
	    if { ![info exists real_quantity([list $product_id $color_choice $size_choice $style_choice])] } {
		if { [info exists return_url] } {
		    ad_returnredirect $return_url
		} else {
		    ad_returnredirect shopping-cart.tcl
		}
		return
	    }

	    set quantity_to_add "[expr $quantity($product_color_size_style) - $real_quantity([list $product_id $color_choice $size_choice $style_choice])]"
	}
    } else {
	set quantity_to_add 0
    }

    if { $quantity_to_add > 0 } {
	set remaining_quantity $quantity_to_add
	while { $remaining_quantity > 0 } {
	    ns_db dml $db "insert into ec_items
	    (item_id, product_id, color_choice, size_choice, style_choice, order_id, in_cart_date)
	    values
	    (ec_item_id_sequence.nextval, $product_id, '[DoubleApos $color_choice]', '[DoubleApos $size_choice]', '[DoubleApos $style_choice]', $order_id, sysdate)
	    "
	    set remaining_quantity [expr $remaining_quantity - 1]
	}
    } elseif { $quantity_to_add < 0 } {
	set remaining_quantity [expr abs($quantity_to_add)]
	
	set rows_to_delete [list]
	while { $remaining_quantity > 0 } {
	    # determine the rows to delete in ec_items (the last instance of this product within this order)
	    if { [llength $rows_to_delete] > 0 } {
		set extra_condition "and item_id not in ([join $rows_to_delete ", "])"
	    } else {
		set extra_condition ""
	    }
	    lappend rows_to_delete [database_to_tcl_string $db "select max(item_id) from ec_items where product_id=$product_id and color_choice [ec_decode $color_choice "" "is null" "= '[DoubleApos $color_choice]'"] and size_choice [ec_decode $size_choice "" "is null" "= '[DoubleApos $size_choice]'"] and style_choice [ec_decode $style_choice "" "is null" "= '[DoubleApos $style_choice]'"] and order_id=$order_id $extra_condition"]
	    set remaining_quantity [expr $remaining_quantity - 1]
	}
	ns_db dml $db "delete from ec_items where item_id in ([join $rows_to_delete ", "])"
    }
    # otherwise, do nothing
}

ns_db dml $db "end transaction"

if { [info exists return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect shopping-cart.tcl
}
