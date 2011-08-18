# $Id: one.tcl,v 3.2 2000/03/07 05:57:10 eveander Exp $
set_the_usual_form_variables
# order_id

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

set selection [ns_db 1row $db "select * from ec_orders where order_id=$order_id"]
set_variables_after_query

set selection [ns_db 0or1row $db "select first_names, last_name from users where user_id=[ns_dbquotevalue $user_id]"]
if { ![empty_string_p $selection] } {
    set_variables_after_query
} else {
    set first_names ""
    set last_name ""
}

ReturnHeaders
ns_write "[ad_admin_header "One Order"]

<h2>One Order</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] "One Order"]

<hr>

<h3>Overview</h3>

[ec_decode $order_state "void" "<table>" "<table width=90%>"]
<tr>
<td align=right><b>Order ID</td>
<td>$order_id</td>
<td rowspan=4 align=right valign=top>[ec_decode $order_state "void" "" "<pre>[ec_formatted_price_shipping_gift_certificate_and_tax_in_an_order $db $order_id]</pre>"]</td>
</tr>
<tr>
<td align=right><b>Ordered by</td>
<td><a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a></td>
</tr>
<tr>
<td align=right><b>Confirmed date</td>
<td>[util_AnsiDatetoPrettyDate $confirmed_date]</td>
</tr>
<tr>
<td align=right><b>Order state</td>
<td>[ec_decode $order_state "void" "<font color=red>void</font>" $order_state]</td>
</tr>
</table>
<p>


<p>
"

if { $order_state == "void" } {
    ns_write "<h3>Details of Void</h3>
<blockquote>
Voided by: <a href=\"/admin/users/one.tcl?user_id=$voided_by\">[database_to_tcl_string_or_null $db "select first_names || ' ' || last_name from users where user_id=[ns_dbquotevalue $voided_by]"]</a>
<br>
Date: [util_AnsiDatetoPrettyDate $voided_date]
<br>
[ec_decode $reason_for_void "" "" "Reason: [ec_display_as_html $reason_for_void]"]
</blockquote>
"
}

ns_write "
[ec_decode $cs_comments "" "" "<h3>Comments</h3>\n<blockquote>[ec_display_as_html $cs_comments]</blockquote>"]

<ul>
<li><a href=\"comments.tcl?[export_url_vars order_id]\">Add/Edit Comments</a>
</ul>

<h3>Items</h3>
<ul>
"

set selection [ns_db select $db "select p.product_name, p.product_id, i.price_name, i.price_charged, count(*) as quantity, i.item_state, i.color_choice, i.size_choice, i.style_choice
from ec_items i, ec_products p
where i.product_id=p.product_id
and i.order_id=$order_id
group by p.product_name, p.product_id, i.price_name, i.price_charged, i.item_state, i.color_choice, i.size_choice, i.style_choice"]

set items_ul ""

# We want to display these by item (with all order states in parentheses), like:
# Quantity 3: #2 Standard Pencils; Our Price: $0.99 (2 shipped, 1 to_be_shipped).
# This UI will break if the customer has more than one of the same product with
# different prices in the same order (the shipment summary is by product_id).

set old_product_color_size_style_price_price_name [list]
# set old_product_id 0
set item_quantity 0
set state_list [list]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    set product_color_size_style_price_price_name [list $product_id $color_choice $size_choice $style_choice $price_charged $price_name]

    set option_list [list]
    if { ![empty_string_p $color_choice] } {
	lappend option_list "Color: $color_choice"
    }
    if { ![empty_string_p $size_choice] } {
	lappend option_list "Size: $size_choice"
    }
    if { ![empty_string_p $style_choice] } {
	lappend option_list "Style: $style_choice"
    }
    set options [join $option_list ", "]

    # it's OK to compare tcl lists with != because lists are really strings in tcl
    if { $product_color_size_style_price_price_name != $old_product_color_size_style_price_price_name && [llength $old_product_color_size_style_price_price_name] != 0 } {
	append items_ul "<li>Quantity $item_quantity: 
	$item_description ([join $item_state_list ", "])
	"
	if { [llength $item_state_list] != 1 || [lindex [split [lindex $item_state_list 0] " "] 1] != "void" } {
	    # i.e., if the items of this product_id are not all void
	    # (I know that "if" statement could be written more compactly,
	    # but I didn't want to offend Philip by relying on Tcl's internal
	    # representation of a list)

	    # EVE: have to make items-void.tcl take more than just product_id
	    append items_ul "<font size=-1>(<a href=\"items-void.tcl?[export_url_vars order_id]&product_id=[lindex $old_product_color_size_style_price_price_name 0]\">remove</a>)</font>"
	}

	append items_ul "<br>
	[ec_shipment_summary $db_sub [lindex $old_product_color_size_style_price_price_name 0] [lindex $old_product_color_size_style_price_price_name 1] [lindex $old_product_color_size_style_price_price_name 2] [lindex $old_product_color_size_style_price_price_name 3] [lindex $old_product_color_size_style_price_price_name 4] [lindex $old_product_color_size_style_price_price_name 5] $order_id]
	"
	set item_state_list [list]
	set item_quantity 0
    }

    lappend item_state_list "$quantity $item_state"
    set item_quantity [expr $item_quantity + $quantity]
    set item_description "<a href=\"/admin/ecommerce/products/one.tcl?product_id=$product_id\">$product_name</a>; [ec_decode $options "" "" "$options; "]$price_name: [ec_pretty_price $price_charged]"
    set old_product_color_size_style_price_price_name [list $product_id $color_choice $size_choice $style_choice $price_charged $price_name]
}

if { [llength $old_product_color_size_style_price_price_name] != 0 } {
    # append the last line
    append items_ul "<li>Quantity $item_quantity: 
    $item_description ([join $item_state_list ", "])
    "
    if { [llength $item_state_list] != 1 || [lindex [split [lindex $item_state_list 0] " "] 1] != "void" } {
	# i.e., if the items of this product_id are not all void
	append items_ul "<font size=-1>(<a href=\"items-void.tcl?[export_url_vars order_id]&product_id=[lindex $old_product_color_size_style_price_price_name 0]\">remove</a>)</font>"
    }
    append items_ul "<br>
    [ec_shipment_summary $db_sub [lindex $old_product_color_size_style_price_price_name 0] [lindex $old_product_color_size_style_price_price_name 1] [lindex $old_product_color_size_style_price_price_name 2] [lindex $old_product_color_size_style_price_price_name 3] [lindex $old_product_color_size_style_price_price_name 4] [lindex $old_product_color_size_style_price_price_name 5] $order_id]
    "
}



ns_write "$items_ul"

if { $order_state == "authorized_plus_avs" || $order_state == "authorized_minus_avs" || $order_state == "partially_fulfilled" } {
    ns_write "<p>
    <li><a href=\"fulfill.tcl?[export_url_vars order_id]\">Record a Shipment</a>
    <li><a href=\"items-add.tcl?[export_url_vars order_id]\">Add Items</a>
    "
}
if { $order_state == "fulfilled" || $order_state == "partially_fulfilled" } {
    ns_write "<p><li><a href=\"items-return.tcl?[export_url_vars order_id]\">Mark Items Returned</a>"
}

ns_write "</ul>

<p>

<h3>Details</h3>

<table>
<tr>
<td align=right valign=top><b>Ship to</b></td>
<td>[ec_display_as_html [ec_pretty_mailing_address_from_ec_addresses $db $shipping_address]]<br>
"
if { $order_state == "confirmed" || $order_state == "authorized_plus_avs" || $order_state == "authorized_minus_avs" || $order_state == "partially_fulfilled" } {
    ns_write "(<a href=\"address-add.tcl?[export_url_vars order_id]\">modify</a>)"
}
ns_write "
</td>
</tr>
"

if { ![empty_string_p $creditcard_id] } {
    ns_write "<tr>
    <td align=right valign=top><b>Credit card</b></td>
    <td>[ec_display_as_html [ec_creditcard_summary $db $creditcard_id] ]
    <br>
    (<a href=\"creditcard-add.tcl?[export_url_vars order_id]\">modify</a>)</td>
    </tr>\n"
}

ns_write "
<tr>
<td align=right><b>In basket date</b></td>
<td>[util_AnsiDatetoPrettyDate $in_basket_date]</td>
</tr>
<tr>
<td align=right><b>Confirmed date</b></td>
<td>[util_AnsiDatetoPrettyDate $confirmed_date]</td>
</tr>
<tr>
<td align=right><b>Authorized date</b></td>
<td>[util_AnsiDatetoPrettyDate $authorized_date]</td>
</tr>
<tr>
<td align=right><b>Base shipping charged</b></td>
<td>[ec_pretty_price $shipping_charged]</td>
</tr>
</table>

<h3>Financial Transactions</h3>
"

set table_header "<table border>
<tr><th>ID</th><th>Date</th><th>Creditcard Last 4</th><th>Amount</th><th>Type</th><th>To Be Captured</th><th>Auth Date</th><th>Mark Date</th><th>Sett Date</th><th>Refund Date</th><th>Refund Sett Date</th><th>Failed</th></tr>
"

set selection [ns_db select $db "select t.transaction_id, t.inserted_date, t.transaction_amount, t.transaction_type, t.to_be_captured_p, t.authorized_date, t.marked_date, t.settled_date, t.refunded_date, t.refund_settled_date, t.failed_p, c.creditcard_last_four
from ec_financial_transactions t, ec_creditcards c
where t.creditcard_id=c.creditcard_id
and t.order_id=$order_id
order by transaction_id"]

set transaction_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $transaction_counter == 0 } {
	ns_write $table_header
    }
    ns_write "<tr>
    <td>$transaction_id</td>
    <td>[ec_nbsp_if_null [util_AnsiDatetoPrettyDate $inserted_date]]</td>
    <td>$creditcard_last_four</td>
    <td>[ec_pretty_price $transaction_amount]</td>
    <td>[ec_decode $transaction_type "charge" "authorization to charge" "intent to refund"]</td>
    <td>[ec_nbsp_if_null [ec_decode $transaction_type "refund" "Yes" [ec_decode $to_be_captured_p "t" "Yes" "f" "No" ""]]]</td>
    <td>[ec_nbsp_if_null [util_AnsiDatetoPrettyDate $authorized_date]]</td>
    <td>[ec_nbsp_if_null [util_AnsiDatetoPrettyDate $marked_date]]</td>
    <td>[ec_nbsp_if_null [util_AnsiDatetoPrettyDate $settled_date]]</td>
    <td>[ec_nbsp_if_null [util_AnsiDatetoPrettyDate $refunded_date]]</td>
    <td>[ec_nbsp_if_null [util_AnsiDatetoPrettyDate $refund_settled_date]]</td>
    <td>[ec_nbsp_if_null [ec_decode $failed_p "t" "Yes" "f" "No" ""]]</td>
    </tr>
    "
    incr transaction_counter
}

if { $transaction_counter != 0 } {
    ns_write "</table>
    "
} else {
    ns_write "<blockquote>None Found</blockquote>"
}

ns_write "
<h3>Shipments</h3>
<blockquote>
"


set selection [ns_db select $db "select s.shipment_id, s.address_id, s.shipment_date, s.expected_arrival_date, s.carrier, s.tracking_number, s.actual_arrival_date, s.actual_arrival_detail, p.product_name, p.product_id, i.price_name, i.price_charged, count(*) as quantity
from ec_shipments s, ec_items i, ec_products p
where i.shipment_id=s.shipment_id
and i.product_id=p.product_id
and s.order_id=$order_id
group by s.shipment_id, s.address_id, s.shipment_date, s.expected_arrival_date, s.carrier, s.tracking_number, s.actual_arrival_date, s.actual_arrival_detail, p.product_name, p.product_id, i.price_name, i.price_charged
order by s.shipment_id"]

set old_shipment_id 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $shipment_id != $old_shipment_id } {
	if { $old_shipment_id != 0 } {
	    ns_write "</ul>
	    <br>
	    <p>"
	}
	ns_write "<table width=90%>
	<tr><td width=50% valign=top>Shipment ID: $shipment_id<br>
	Date: [util_AnsiDatetoPrettyDate $shipment_date]<br>
	[ec_decode $expected_arrival_date "" "" "Expected Arrival: [util_AnsiDatetoPrettyDate $expected_arrival_date]<br>"]
	[ec_decode $carrier "" "" "Carrier: $carrier<br>"]
	[ec_decode $tracking_number "" "" "Tracking #: $tracking_number<br>"]
	[ec_decode $actual_arrival_date "" "" "Actual Arrival Date: [util_AnsiDatetoPrettyDate $actual_arrival_date]<br>"]
	[ec_decode $actual_arrival_detail "" "" "Actual Arrival Detail: $actual_arrival_detail<br>"]
	(<a href=\"track.tcl?shipment_id=$shipment_id\">track</a>)
	</td>
	<td valign=top width=50%>[ec_display_as_html [ec_pretty_mailing_address_from_ec_addresses $db_sub $address_id]]</td>
	</tr>
	</table>
	<ul>
	"
    }
    ns_write "<li>Quantity $quantity: $product_name"
    set old_shipment_id $shipment_id
}

if { $old_shipment_id == 0 } {
    ns_write "No Shipments Have Been Made"
} else {
    ns_write "</ul>"
}

ns_write "</blockquote>
<h3>Returns</h3>
<blockquote>
"

set selection [ns_db select $db "select r.refund_id, r.refund_date, r.refunded_by, r.refund_reasons, r.refund_amount, u.first_names, u.last_name, p.product_name, p.product_id, i.price_name, i.price_charged, count(*) as quantity
from ec_refunds r, users u, ec_items i, ec_products p
where r.order_id=$order_id
and r.refunded_by=u.user_id
and i.refund_id=r.refund_id
and p.product_id=i.product_id
group by r.refund_id, r.refund_date, r.refunded_by, r.refund_reasons, r.refund_amount, u.first_names, u.last_name, p.product_name, p.product_id, i.price_name, i.price_charged"]

set old_refund_id 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $refund_id != $old_refund_id } {
	if { $old_refund_id != 0 } {
	    ns_write "</ul>
	    <br>
	    <p>"
	}
	ns_write "Refund ID: $refund_id<br>
	Date: [util_AnsiDatetoPrettyDate $refund_date]<br>
	Amount: [ec_pretty_price $refund_amount]<br>
	Refunded by: <a href=\"/admin/users/one.tcl?user_id=$refunded_by\">$first_names $last_name</a><br>
	Reason: $refund_reasons
	<ul>
	"
    }
    ns_write "<li>Quantity $quantity: $product_name"
    set old_refund_id $refund_id
}

if { $old_refund_id == 0 } {
    ns_write "No Returns Have Been Made"
} else {
    ns_write "</ul>"
}


ns_write "</blockquote>"


if { $order_state != "void" } {
    ns_write "<h3>Actions</h3>
    <ul>
    <li><a href=\"void.tcl?[export_url_vars order_id]\">Void Order</a>
    "
}
ns_write "</ul>
[ad_admin_footer]
"
