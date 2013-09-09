# /tcl/ecommerce-money-computations.tcl
ad_library {

  Computes the total price of an order. Note that it must have already
  had the price, shipping and tax filled in for each item and
  shipping, tax, and gift_certificate amount filled in for the order.
  Any confirmed (or later) order meets these criteria.

  This will determine the price for an item by returning the minimum of:
    - regular price for that product
    - price of that product for any user_class the user_id is in
    - current sale price where no offer code is needed
    - current sale price where the offer code is the same as $offer_code

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id ecommerce-money-computations.tcl,v 3.1.2.7 2000/08/20 00:50:23 hbrock Exp
}

proc ec_lowest_price_and_price_name_for_an_item { product_id user_id {offer_code ""} } {
    set lowest_price 0
    set lowest_price_name ""
    set reg_price [db_string get_price "select price from ec_products where product_id=:product_id"]
    if { ![empty_string_p $reg_price] } {
	set lowest_price $reg_price
	set lowest_price_name "Our Price"
    }

    if { [ad_parameter UserClassApproveP ecommerce] } {
	set additional_user_class_restriction "and m.user_class_approved_p = 't'"
    } else {
	set additional_user_class_restriction "and (m.user_class_approved_p is null or m.user_class_approved_p='t')"
    }

    db_foreach get_product_infos "
        select p.price, c.user_class_name
        from ec_product_user_class_prices p, ec_user_classes c
        where p.product_id=:product_id
        and p.user_class_id=c.user_class_id
        and p.user_class_id in (select m.user_class_id from ec_user_class_user_map m where m.user_id=:user_id $additional_user_class_restriction)
    " {
	if { ![empty_string_p $price] && $price < $lowest_price } {
	    set lowest_price $price
	    # only include the user_class_name in the name of the price if
	    # the user is allowed to see what user classes they're in
	    if { [ad_parameter UserClassUserViewP ecommerce] == 1 } {
		set lowest_price_name "$user_class_name Price"
	    } else {
		set lowest_price_name "Special Price"
	    }
	}
    }
    if { ![empty_string_p $offer_code] } {
	set or_part_of_query "or offer_code=:offer_code"
    } else {
	set or_part_of_query ""
    }
    db_foreach get_sale_prices "select sale_price, sale_name
    from ec_sale_prices_current
    where product_id=:product_id
    and (offer_code is null $or_part_of_query)
    " {

	if { ![empty_string_p $sale_price] && $sale_price < $lowest_price } {
	    set lowest_price $sale_price
	    set lowest_price_name $sale_name
	}
    }
    return [list $lowest_price $lowest_price_name]
}

# I've included the product_id, order_id, and shipping_method in the arguments because they're
# always already known in any environment where I intend to call this procedure, so I might as
# well save two database hits.
proc ec_shipping_price_for_one_item {item_id product_id order_id shipping_method} {
    # get shipping, shipping_additional, default_shipping_per_item, weight, weight_shipping_cost
    # to determine regular shipping price

    db_1row get_shipping_info "select shipping, shipping_additional, weight from ec_products where product_id=:product_id"
    
    db_1row get_default_shipping_info "select default_shipping_per_item, weight_shipping_cost from ec_admin_settings"

    
    # calculate regular shipping price
    if { ![empty_string_p $shipping_additional] } {
	# find out if this is the first instance of the product in this order, or a later instance
	set first_instance [db_string get_first_item "select min(item_id) from ec_items where product_id=:product_id and order_id:order_id"]
	if { $item_id != $first_instance } {
	    set reg_shipping $shipping_additional
	} elseif { ![empty_string_p $shipping] } {
	    set reg_shipping $shipping
	}
    } elseif { ![empty_string_p $shipping] } {
	set reg_shipping $shipping
    } elseif { ![empty_string_p $default_shipping_per_item] } {
	set reg_shipping $default_shipping_per_item
    } elseif { ![empty_string_p $weight] && ![empty_string_p $weight_shipping_cost] } {
	set reg_shipping [expr $weight * $weight_shipping_cost]
    } else {
	set reg_shipping 0
    }

    set total_shipping_cost $reg_shipping
    # see if we have to add something for express shipping
    if { $shipping_method == "express" } {
	db_1row get_exp_info "select add_exp_amount_per_item, add_exp_amount_by_weight from ec_admin_settings"

	if { ![empty_string_p $add_exp_amount_per_item] } {
	    set total_shipping_cost [expr $total_shipping_cost + $add_exp_amount_per_item]
	}
	if { ![empty_string_p $add_exp_amount_by_weight] } {
	    set total_shipping_cost [expr $total_shipping_cost + ([ec_decode $weight "" 0 $weight] * $add_exp_amount_by_weight)]
	}
    }
    return $total_shipping_cost
}

# Returns price, price_name, shipping, price_tax, and shipping_tax (all in a list) for one item.
# I will make user_class_id_list default_shipping_per_item, weight_shipping_cost,
# add_exp_amount_per_item, add_exp_amount_by_weight, tax_rate, and shipping_p arguments
# because they are constant, so I don't want to have to pull them from the database each
# time (this procedure is called from within a loop)
# For preconfirmed orders.
proc ec_price_price_name_shipping_price_tax_shipping_tax_for_one_item { product_id offer_code item_id order_id shipping_method user_class_id_list default_shipping_per_item weight_shipping_cost add_exp_amount_per_item add_exp_amount_by_weight tax_rate shipping_p } {

    ##
    ## Part 1: Get Price & Price Name
    ##

    set lowest_price 0
    set lowest_price_name "none"
    set reg_price [db_string get_item_price "select price from ec_products where product_id=:product_id"]
    if { ![empty_string_p $reg_price] } {
	set lowest_price $reg_price
	set lowest_price_name "Our Price"
    }
    if { [llength $user_class_id_list] > 0 } {
	db_foreach get_price_and_name "select p.price, c.user_class_name
	from ec_product_user_class_prices p, ec_user_classes c
	where p.product_id=:product_id
	and p.user_class_id=c.user_class_id
	and p.user_class_id in ([join $user_class_id_list ", "])" {
	

	    if { ![empty_string_p $price] && $price < $lowest_price } {
		set lowest_price $price
	    # only include the user_class_name in the name of the price if
	    # the user is allowed to see what user classes they're in
		if { [ad_parameter UserClassUserViewP ecommerce] == 1 } {
		    set lowest_price_name "$user_class_name Price"
		} else {
		    set lowest_price_name "Special Price"
		}
	    }
	}
    }

    if { ![empty_string_p $offer_code] } {
	set or_part_of_query "or offer_code=:offer_code"
    } else {
	set or_part_of_query ""
    }
    db_foreach get_sale_prices "select sale_price, sale_name
    from ec_sale_prices_current
    where product_id=:product_id
    and (offer_code is null $or_part_of_query)
    " {
    
	
	if { ![empty_string_p $sale_price] && $sale_price < $lowest_price } {
	    set lowest_price $sale_price
	    set lowest_price_name $sale_name
	}
    }

    # To return:
    set price_to_return $lowest_price
    set price_name_to_return $lowest_price_name

    ##
    ## Part 2: Determine Shipping Cost
    ##

   db_1row get_shipping_costs "select shipping, shipping_additional, weight from ec_products where product_id=:product_id"

    
    # calculate regular shipping price
    if { ![empty_string_p $shipping_additional] } {
	# find out if this is the first instance of the product in this order, or a later instance
	set first_instance [db_string get_first_instance "select min(item_id) from ec_items where product_id=:product_id and order_id=:order_id"]
	if { $item_id != $first_instance } {
	    set reg_shipping $shipping_additional
	} elseif { ![empty_string_p $shipping] } {
	    set reg_shipping $shipping
	}
    } elseif { ![empty_string_p $shipping] } {
	set reg_shipping $shipping
    } elseif { ![empty_string_p $default_shipping_per_item] } {
	set reg_shipping $default_shipping_per_item
    } elseif { ![empty_string_p $weight] && ![empty_string_p $weight_shipping_cost] } {
	set reg_shipping [expr $weight * $weight_shipping_cost]
    } else {
	set reg_shipping 0
    }

    set total_shipping_cost $reg_shipping
    # see if we have to add something for express shipping
    if { $shipping_method == "express" } {
	if { ![empty_string_p $add_exp_amount_per_item] } {
	    set total_shipping_cost [expr $total_shipping_cost + $add_exp_amount_per_item]
	}
	if { ![empty_string_p $add_exp_amount_by_weight] } {
	    set total_shipping_cost [expr $total_shipping_cost + ([ec_decode $weight "" 0 $weight] * $add_exp_amount_by_weight)]
	}
    }
    
    # To return:
    set shipping_to_return $total_shipping_cost

    ##
    ## Part 3: Determine Tax on the Price and Tax on the Shipping
    ##

    if { $tax_rate == 0 } {
	set price_tax_to_return 0
	set shipping_tax_to_return 0
    } else { 
	set price_tax_to_return [expr $price_to_return * $tax_rate]
    
	if { $shipping_p == "f" } {
	    set shipping_tax_to_return 0
	} else {
	    set shipping_tax_to_return [expr $shipping_to_return * $tax_rate]
	}
    }

    return [list $price_to_return $price_name_to_return $shipping_to_return $price_tax_to_return $shipping_tax_to_return]

}

# returns a list containing the total price, total shipping, gift_certificate amount
# and total tax for an order
# this assumes all prices and shipping and tax charges are filled in for the order
# and items
# gift_certificate amount is: taken from database for confirmed orders, or calculated
#                             for not yet confirmed orders
# Note: the price it shows is really price charged minus price refunded, similarly
# for shipping and tax.
proc ec_price_shipping_gift_certificate_and_tax_in_an_order { order_id } {

    db_1row get_confirmed_info {
	select confirmed_date, user_id,
	       ec_total_price(:order_id) as total_price,
	       ec_total_shipping(:order_id) as total_shipping,
	       ec_total_tax(:order_id) as total_tax
	from ec_orders
	where order_id = :order_id
    }

    # if order has been confirmed, use the gift certificate amount actually used
    # otherwise determine what it will be using ec_gift_certificate_balance($user_id)

    if { [empty_string_p $confirmed_date] } {
	set gift_certificate_balance [db_string get_ec_gc_bal "select ec_gift_certificate_balance(:user_id) from dual"]
	set gift_certificate_amount [ec_min [expr $total_price + $total_shipping + $total_tax] $gift_certificate_balance]
    } else {
	# the gift certificate amount is always up-to-date (includes reinstatements)
	set gift_certificate_amount [db_string get_gc_amount "select ec_order_gift_cert_amount(:order_id) from dual"]
    }

    return [list $total_price $total_shipping $gift_certificate_amount $total_tax]
}



