# $Id: items-add-4.tcl,v 3.1.2.1 2000/04/28 15:08:44 carsten Exp $
set_the_usual_form_variables
# item_id, order_id, product_id, color_choice, size_choice, style_choice, price_charged, price_name

# minor error checking
if { [empty_string_p $price_charged] || [regexp {[^0-9\.]} $price_charged] } {
    ad_return_complaint 1 "The price must be a number (no special characters)."
    return
}

set db [ns_db gethandle]

# double-click protection
if { [database_to_tcl_string $db "select count(*) from ec_items where item_id=$item_id"] > 0 } {
    ad_returnredirect "one.tcl?[export_url_vars order_id]"
    return
}

# must have associated credit card
if [empty_string_p [database_to_tcl_string $db "select creditcard_id from ec_orders where order_id=$order_id"]] {
    ad_return_error "Unable to add items to this order." "
       This order does not have an associated credit card, so new items cannot be added.
       <br>Please create a new order instead."
    return
}


set shipping_method [database_to_tcl_string $db "select shipping_method from ec_orders where order_id=$order_id"]

ns_db dml $db "begin transaction"

ns_db dml $db "insert into ec_items
(item_id, product_id, color_choice, size_choice, style_choice, order_id, in_cart_date, item_state, price_charged, price_name)
values
($item_id, $product_id, '$QQcolor_choice', '$QQsize_choice', '$QQstyle_choice', $order_id, sysdate, 'to_be_shipped', $price_charged, '$QQprice_name')
"

# I calculate the shipping after it's inserted because this procedure goes and checks
# whether this is the first instance of this product in this order.
# I know it's non-ideal efficiency-wise, but this procedure (written for the user pages)
# is already written and it works.

set shipping_price [ec_shipping_price_for_one_item $db $item_id $product_id $order_id $shipping_method]

ns_db dml $db "update ec_items set shipping_charged='$shipping_price' where item_id=$item_id"

ns_db dml $db "end transaction"

ad_returnredirect "one.tcl?[export_url_vars order_id]"
