# $Id: items-void.tcl,v 3.0.4.1 2000/04/28 15:08:45 carsten Exp $
set_the_usual_form_variables
# order_id, product_id

# we need them to be logged in
set customer_service_rep [ad_verify_and_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# in case they reload this page after completing the void process:
if { [database_to_tcl_string $db "select count(*) from ec_items where order_id=$order_id and product_id=$product_id and item_state<>'void'"] == 0 } {
    ad_return_complaint 1 "<li>These items are already void; perhaps you are using an old form.  <a href=\"one.tcl?[export_url_vars order_id]\">Return to the order.</a>"
    return
}

set n_items [database_to_tcl_string $db "select count(*) from ec_items where order_id=$order_id and product_id=$product_id"]

if { $n_items > 1 } {
    set item_or_items "Items"
} else {
    set item_or_items "Item"
}

ReturnHeaders
ns_write "[ad_admin_header "Void $item_or_items"]

<h2>Void $item_or_items</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?order_id=$order_id" "One Order"] "$item_or_items"]

<hr>
<blockquote>
<form method=post action=items-void-2.tcl>
[export_form_vars order_id product_id]
"

# we have to take care of some cases (hopefully #1, the simplest, will be most
# prevalent)
# different cases get different wording and cases 1-2 are functionally different
# than cases 3-4
# 1. there's only one item in this order with this product_id and it hasn't shipped yet
# 2. there's only one item in this order with this product_id and it's already shipped
# 3. more than one item in this order with this product_id and no non-void items have
#    already shipped
# 4. more than one item in this order with this product_id and at least one non-void
#    item has already shipped

if { $n_items == 1 } {
    # cases 1 & 2 (only differ by a warning message)
    # we assume it's not void, otherwise they wouldn't have been given the link to
    # this page
    set item_state [database_to_tcl_string $db "select item_state from ec_items where order_id=$order_id and product_id=$product_id"]

    if { $item_state == "shipped" || $item_state == "arrived" || $item_state == "received_back" } {
	ns_write "<font color=red>Warning:</font> our records show that this item has already
	shipped, which means that the customer has already been charged for this
	item. Voiding an item will not cause the customer's credit card to be
	refunded (you can only do that by marking it \"received back\").
	<p>
	"
    }    
    ns_write "Please confirm that you want to void this item.
    "

} else {
    # cases 3 & 4 (only differ by a warning message)
    set n_shipped_items [database_to_tcl_string $db "select count(*) from ec_items where order_id=$order_id and product_id=$product_id and item_state in ('shipped','arrived','received_back')"]

    if { $n_shipped_items > 0 } {
	ns_write "<font>Warning:</font> our records show that at least one of these
	items has already shipped, which means that the customer has already
	been charged (for shipped items only). Voiding an item will not cause
	the customer's credit card to be refunded (you can only do that by marking
	it \"received back\").
	<p>
	"
    }
    ns_write "Please check off the item(s) you wish to void.
    <table>
    <tr><th>Void Item</th><th>Product</th><th>Item State</th>"

    set selection [ns_db select $db "select i.item_id, i.item_state, p.product_name, i.price_name, i.price_charged
    from ec_items i, ec_products p
    where i.product_id=p.product_id
    and i.order_id=$order_id
    and i.product_id=$product_id"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_write "<tr><td align=center>"
	if { $item_state == "void" } {
	    ns_write " (already void) "
	} else {
	    ns_write "<input type=checkbox name=item_id value=$item_id>"
	}
	ns_write "</td><td>$product_name; $price_name: [ec_pretty_price $price_charged]</td><td>$item_state</td></tr>"
    }

    ns_write "</table>"

}

ns_write "<p>

</blockquote>
<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"