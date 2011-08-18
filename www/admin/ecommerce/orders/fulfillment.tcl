# $Id: fulfillment.tcl,v 3.0 2000/02/06 03:19:06 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Order Fulfillment"]

<h2>Order Fulfillment</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] "Fulfillment"]

<hr>
(these <a href=\"fulfillment-items-needed.tcl\">items</a> are needed in order to fulfill all outstanding orders)
<p>
"

set old_order_state ""
set old_shipping_method ""

set db [ns_db gethandle]

set selection [ns_db select $db "select o.order_id, o.confirmed_date, o.order_state, o.shipping_method, u.first_names, u.last_name, u.user_id
from ec_orders_shippable o, users u
where o.user_id=u.user_id
order by o.shipping_method, o.order_state, o.order_id"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $shipping_method != $old_shipping_method } {
	if { $old_shipping_method != "" } {
	    ns_write "</ul>
	    </blockquote>"
	}

	ns_write "<h3>[string toupper "$shipping_method shipping"]</h3>
	<blockquote>"
    }

    if { $order_state != $old_order_state || $shipping_method != $old_shipping_method } {
	if { $shipping_method == $old_shipping_method } {
	    ns_write "</ul>"
	}
	ns_write "<b>Orders in state '$order_state'</b>
	<ul>
	"
    }

    ns_write "<li>"
    ns_write "[ec_order_summary_for_admin $order_id $first_names $last_name $confirmed_date $order_state $user_id]"
    ns_write " \[<a href=\"fulfill.tcl?order_id=$order_id\">Fulfill</a>\]\n"

    set old_shipping_method $shipping_method
    set old_order_state $order_state
}


if { $old_shipping_method != "" } {
    ns_write "
    </ul>
    </blockquote>
    "
}

ns_write "[ad_admin_footer]
"
