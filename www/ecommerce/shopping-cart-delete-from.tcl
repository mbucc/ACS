# $Id: shopping-cart-delete-from.tcl,v 3.0.4.1 2000/04/28 15:10:03 carsten Exp $
set_the_usual_form_variables
# product_id

set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]

set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_session_id=$user_session_id and order_state='in_basket'"]

if { [empty_string_p $order_id] } {
    # then they probably got here by pushing "Back", so just redirect them
    # into their empty shopping cart
    ad_returnredirect shopping-cart.tcl
    return
}

ns_db dml $db "delete from ec_items where order_id=$order_id and product_id=$product_id"

ad_returnredirect shopping-cart.tcl
