# $Id: shopping-cart-retrieve-2.tcl,v 3.1.2.1 2000/04/28 15:10:03 carsten Exp $
set_form_variables 0
# possibly usca_p

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# Cases that have to be dealt with:
# 1. User has no saved carts.
# 2. User has saved cart(s) and no current cart.
# 3. User has saved cart(s) and one current cart.

set saved_carts ""

# user session tracking
set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]

ec_create_new_session_if_necessary "" shopping_cart_required
# typeA

set selection [ns_db select $db "select to_char(o.in_basket_date,'Month DD, YYYY') as formatted_in_basket_date, o.in_basket_date, o.order_id, count(*) as n_products
from ec_orders o, ec_items i
where user_id=$user_id
and order_state='in_basket'
and saved_p='t'
and i.order_id=o.order_id
group by o.order_id, to_char(o.in_basket_date,'Month DD, YYYY'), o.in_basket_date
order by o.in_basket_date"]

set cart_counter 0
while { [ns_db getrow $db $selection] } {
    incr cart_counter
    set_variables_after_query
    append saved_carts "<form method=post action=\"shopping-cart-retrieve-3.tcl\">
    [export_form_vars order_id]
    <li>$formatted_in_basket_date, $n_products item(s)
    <input type=submit name=submit value=\"View\">
    <input type=submit name=submit value=\"Retrieve\">
    <input type=submit name=submit value=\"Discard\">
    </form>
    "
}

if {[empty_string_p $saved_carts] } {
    append saved_carts "No shopping carts were found.\n"
}

ad_return_template