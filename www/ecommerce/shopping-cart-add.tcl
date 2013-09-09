#  www/ecommerce/shopping-cart-add.tcl
ad_page_contract {
 This adds an item to an 'in_basket' order, although if there exists a 'confirmed'
 order for this user_session_id, the user is told they have to wait because
 'confirmed' orders can potentially become 'in_basket' orders (if authorization
 fails), and we can only have one 'in_basket' order for this user_session_id at
 a time.  Most orders are only in the 'confirmed' state for a few seconds, except
 for those whose credit card authorizations are inconclusive.  Furthermore, it is
 unlikely for a user to start adding things to their shopping cart right after they've
 made an order.  So this case is unlikely to occur often.  I will include a ns_log Notice so that any occurrences will be logged.

    @param product_id:integer
    @param size_choice
    @param color_choice
    @param style_choice
    @param usca_p:optional
  @author
  @creation-date
  @cvs-id shopping-cart-add.tcl,v 3.3.2.6 2000/08/17 18:01:28 seb Exp
} { 
    product_id:integer
    size_choice
    color_choice
    style_choice
    usca_p:optional
}




# 1. get user_session_id
# 1.5 see if there exists a 'confirmed' order for this user_session_id
# 2. get order_id
# 3. get item_id
# 4. put item into ec_items, unless there is already an item with that product_id
#    in that order (this is double click protection -- the only way they can increase
#    the quantity of a product in their order is to click on "update quantities" on
#    the shopping cart page (shopping-cart.tcl)
# 5. ad_returnredirect them to their shopping cart

set user_session_id [ec_get_user_session_id]

ec_create_new_session_if_necessary [export_url_vars product_id]

set n_confirmed_orders [db_string get_n_confirmed_orders "select count(*) from ec_orders where user_session_id=:user_session_id and order_state='confirmed'"]

if { $n_confirmed_orders > 0 } {
    ad_return_complaint 1 "Sorry, you have an order for which credit card authorization has not yet taken place. Please wait for the authorization to complete before adding new items to your shopping cart. Thank you."
    return
}

set order_id [db_string get_order_id "select order_id from ec_orders where user_session_id=:user_session_id and order_state='in_basket'"  -default ""]

# This wasn't quite safe (e.g. if an in_basket order gets inserted between
# the beginning of the if statement and the insert statement).

# if { [empty_string_p $order_id] } {
#     set order_id [db_string get_new_order_id "select ec_order_id_sequence.nextval from dual"]
#     # create the order
#     db_dml insert_new_order "insert into ec_orders
#     (order_id, user_session_id, order_state, in_basket_date)
#     values
#     (:order_id, :user_session_id, 'in_basket', sysdate)
#     "
# }

# Here's the airtight way to do it: do the check on order_id, then insert
# a new order where there doesn't exist an old one, then set order_id again
# (because the correct order_id might not be the one set inside the if 
# statement).  It should now be impossible for order_id to be the empty
# string (if it is, log the error and redirect them to product.tcl).

if { [empty_string_p $order_id] } {
     set order_id [db_string get_new_ec_order_id "select ec_order_id_sequence.nextval from dual"]
    # create the order (iff an in_basket order *still* doesn't exist)
    db_dml insert_new_ec_order "insert into ec_orders
    (order_id, user_session_id, order_state, in_basket_date)
    select :order_id, :user_session_id, 'in_basket', sysdate from dual
    where not exists (select 1 from ec_orders where user_session_id=:user_session_id and order_state='in_basket')"

    # now either an in_basket order should have been inserted by the above
    # statement or it was inserted by a different thread milliseconds ago
    set order_id [db_string  get_order_id "select order_id from ec_orders where user_session_id=:user_session_id and order_state='in_basket'" -default ""]

    if { [empty_string_p $order_id] } {
	# I don't expect this to ever happen, but just in case, I'll log
	# the problem and redirect them to product.tcl
 set errormsg "Null order_id on shopping-cart-add.tcl for user_session_id :user_session_id.  Please report this problem to eveander@arsdigita.com."
	
	db_dml insert_problem_into_log "insert into ec_problems_log
	(problem_id, problem_date, problem_details)
	values
	(ec_problem_id_sequence.nextval, sysdate,:errormsg)"
	ad_returnredirect "product?[export_url_vars product_id]"
	return
    }
}

# Insert an item into that order iff an identical item doesn't
# exist (this is double click protection).
# If they want to update quantities, they can do so from the
# shopping cart page.

db_dml insert_new_item_in_order "insert into ec_items
(item_id, product_id, color_choice, size_choice, style_choice, order_id, in_cart_date)
(select ec_item_id_sequence.nextval, :product_id, :color_choice, :size_choice, :style_choice, :order_id, sysdate from dual
   where not exists (select 1 from ec_items where order_id=:order_id and product_id=:product_id and color_choice  [ec_decode $color_choice "" "is null" "= :color_choice"]  and size_choice [ec_decode $size_choice "" "is null" "= :size_choice"] and style_choice [ec_decode $style_choice "" "is null" "= :style_choice"]))"
db_release_unused_handles
ad_returnredirect shopping-cart.tcl
