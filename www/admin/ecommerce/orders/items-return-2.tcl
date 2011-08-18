# $Id: items-return-2.tcl,v 3.0.4.1 2000/04/28 15:08:44 carsten Exp $
set_the_usual_form_variables
# refund_id, order_id, received_back_date (in pieces), reason_for_return,
# either all_items_p or a series of item_ids

# the customer service rep must be logged on
set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# make sure they haven't already inserted this refund
if { [database_to_tcl_string $db "select count(*) from ec_refunds where refund_id=$refund_id"] > 0 } {
    ad_return_complaint 1 "<li>This refund has already been inserted into the database; it looks like you are using an old form.  <a href=\"one.tcl?[export_url_vars order_id]\">Return to the order.</a>"
    return
}

set exception_count 0
set exception_text ""

# they must have either checked "All items" and none of the rest, or
# at least one of the rest and not "All items"
# they also need to have shipment_date filled in

if { [info exists all_items_p] && [info exists item_id] } {
    incr exception_count
    append exception_text "<li>Please either check off \"All items\" or check off some of the items, but not both."
}
if { ![info exists all_items_p] && ![info exists item_id] } {
    incr exception_count
    append exception_text "<li>Please either check off \"All items\" or check off some of the items."
}

# the annoying date stuff
set form [ns_getform]
    
# ns_dbformvalue $form received_back_date date received_back_date will give an error
# message if the day of the month is 08 or 09 (this octal number problem
# we've had in other places).  So I'll have to trim the leading zeros
# from ColValue.received%5fback%5fdate.day
# and stick the new value into the $form ns_set.
    
set "ColValue.received%5fback%5fdate.day" [string trimleft [set ColValue.received%5fback%5fdate.day] "0"]
ns_set update $form "ColValue.received%5fback%5fdate.day" [set ColValue.received%5fback%5fdate.day]

if [catch  { ns_dbformvalue $form received_back_date datetime received_back_date} errmsg ] {
    # maybe they left off time, which is ok; we'll just try to set the date & not the time
    if [catch { ns_dbformvalue $form received_back_date date received_back_date} errmsg] {
	incr exception_count
	append exception_text "<li>The date received back was specified in the wrong format.  The date should be in the format Month DD YYYY.  The time should be in the format HH:MI:SS (seconds are optional), where HH is 01-12, MI is 00-59 and SS is 00-59.\n"
    } else {
	set received_back_date "$received_back_date 00:00:00"
    }
} elseif { [empty_string_p $received_back_date] } {
    incr exception_count
    append exception_text "<li>Please enter the date received back.\n"
} elseif { [string length [set ColValue.received%5fback%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The shipment year needs to contain 4 digits.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint 1 $exception_text
    return
}

ReturnHeaders
ns_write "[ad_admin_header "Specify refund amount"]

<h2>Specify refund amount</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?[export_url_vars order_id]" "One"] "Mark Items Returned"]

<hr>
"

set shipping_refund_percent [ad_parameter ShippingRefundPercent ecommerce]

if { ![info exists all_items_p] } {
    set form [ns_getform]
    set form_size [ns_set size $form]
    set form_counter 0
    
    set item_id_list [list]
    while { $form_counter < $form_size} {
	if { [ns_set key $form $form_counter] == "item_id" } {
	    lappend item_id_list [ns_set value $form $form_counter]
	}
	incr form_counter
    }
    
    set selection [ns_db select $db "select i.item_id, p.product_name, i.price_charged, i.shipping_charged
    from ec_items i, ec_products p
    where i.product_id=p.product_id
    and i.item_id in ([join $item_id_list ", "])
    and i.item_state in ('shipped','arrived')"]
    # the last line is for error checking (we don't want them to push "back" and 
    # try to do a refund again for the same items)
} else {
    set selection [ns_db select $db "select i.item_id, p.product_name, i.price_charged, i.shipping_charged
    from ec_items i, ec_products p
    where i.product_id=p.product_id
    and i.order_id=$order_id
    and i.item_state in ('shipped','arrived')"]
}

# If they select "All items", I want to generate a list of the items because, regardless
# of what happens elsewhere on the site (e.g. an item is added to the order, thereby causing
# the query for all items to return one more item), I want only the items that they confirm
# here to be recorded as part of this return.
if { [info exists all_items_p] } {
    set item_id_list [list]
}

set items_to_print ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { [info exists all_items_p] } {
	lappend item_id_list $item_id
    }
   append items_to_print "<tr><td>$product_name</td><td><input type=text name=\"price_to_refund($item_id)\" value=\"[format "%0.2f" $price_charged]\" size=4> (out of [ec_pretty_price $price_charged])</td><td><input type=text name=\"shipping_to_refund($item_id)\" value=\"[format "%0.2f" [expr $shipping_charged * $shipping_refund_percent]]\" size=4> (out of [ec_pretty_price $shipping_charged])</td></tr>"
}

ns_write "<form method=post action=items-return-3.tcl>
[export_form_vars refund_id order_id item_id_list received_back_date reason_for_return]
<blockquote>
<table border=0 cellspacing=0 cellpadding=10>
<tr><th>Item</th><th>Price to Refund</th><th>Shipping to Refund</th></tr>
$items_to_print
</table>
<p>
"

# we assume that, although only one refund may be done on an item, multiple refunds
# may be done on the base shipping cost, so we show them shipping_charged - shipping_refunded
set base_shipping [database_to_tcl_string $db "select nvl(shipping_charged,0) - nvl(shipping_refunded,0) from ec_orders where order_id=$order_id"]

ns_write "Base shipping charge to refund:
<input type=text name=base_shipping_to_refund value=\"[format "%0.2f" [expr $base_shipping * $shipping_refund_percent]]\" size=4> (out of [ec_pretty_price $base_shipping])

<p>

</blockquote>

<center>
<input type=submit value=\"Continue\">
</center>

[ad_admin_footer]
"