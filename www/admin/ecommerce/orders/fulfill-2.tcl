# $Id: fulfill-2.tcl,v 3.1.2.1 2000/04/28 15:08:43 carsten Exp $
set_the_usual_form_variables
# order_id, shipment_date (in pieces), expected_arrival_date (in pieces),
# carrier, carrier_other, tracking_number,
# either all_items_p or a series of item_ids

# This script shows confirmation page & shipping address

# the customer service rep must be logged on
set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

if { ![empty_string_p $carrier_other] } {
    set carrier $carrier_other
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
    
# ns_dbformvalue $form shipment_date date shipment_date will give an error
# message if the day of the month is 08 or 09 (this octal number problem
# we've had in other places).  So I'll have to trim the leading zeros
# from ColValue.shipment%5fdate.day and ColValue.expected%5farrival%5fdate.day
# and stick the new value into the $form ns_set.
    
set "ColValue.shipment%5fdate.day" [string trimleft [set ColValue.shipment%5fdate.day] "0"]
ns_set update $form "ColValue.shipment%5fdate.day" [set ColValue.shipment%5fdate.day]

set "ColValue.expected%5farrival%5fdate.day" [string trimleft [set ColValue.shipment%5fdate.day] "0"]
ns_set update $form "ColValue.expected%5farrival%5fdate.day" [set ColValue.expected%5farrival%5fdate.day]

if [catch  { ns_dbformvalue $form shipment_date datetime shipment_date} errmsg ] {
    # maybe they left off time, which is ok; we'll just try to set the date & not the time
    if [catch { ns_dbformvalue $form shipment_date date shipment_date} errmsg] {
	incr exception_count
	append exception_text "<li>The shipment date was specified in the wrong format.  The date should be in the format Month DD YYYY.  The time should be in the format HH:MI:SS (seconds are optional), where HH is 01-12, MI is 00-59 and SS is 00-59.\n"
    } else {
	set shipment_date "$shipment_date 00:00:00"
    }
} elseif { [empty_string_p $shipment_date] } {
    incr exception_count
    append exception_text "<li>Please enter a shipment date.\n"
} elseif { [string length [set ColValue.shipment%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The shipment year needs to contain 4 digits.\n"
}

if [catch  { ns_dbformvalue $form expected_arrival_date datetime expected_arrival_date} errmsg ] {
    # maybe they left off time, which is ok; we'll just try to set the date & not the time
    if [catch { ns_dbformvalue $form expected_arrival_date date expected_arrival_date} errmsg] {
	set expected_arrival_date ""
    } else {
	set expected_arrival_date "$expected_arrival_date 00:00:00"
    }
} elseif { [string length [set ColValue.expected%5farrival%5fdate.year]] != 4 && [string length [set ColValue.expected%5farrival%5fdate.year]] != 0 } {
    # if the expected arrival year is non-null, then it needs to contain 4 digits
    incr exception_count
    append exception_text "<li>The expected arrival year needs to contain 4 digits.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint 1 $exception_text
    return
}

ReturnHeaders
ns_write "[ad_admin_header "Confirm that these item(s) have been shipped"]

<h2>Confirm that these item(s) have been shipped</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "fulfillment.tcl" "Fulfillment"] "One Order"]

<hr>
"

set db [ns_db gethandle]
set shipment_id [database_to_tcl_string $db "select ec_shipment_id_sequence.nextval from dual"]

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

    set selection [ns_db select $db "select i.item_id, p.product_name, p.one_line_description, p.product_id, i.price_charged, i.price_name, i.color_choice, i.size_choice, i.style_choice
    from ec_items i, ec_products p
    where i.product_id=p.product_id
    and i.item_id in ([join $item_id_list ", "])"]
} else {
    set selection [ns_db select $db "select i.item_id, p.product_name, p.one_line_description, p.product_id, i.price_charged, i.price_name, i.color_choice, i.size_choice, i.style_choice
    from ec_items i, ec_products p
    where i.product_id=p.product_id
    and i.order_id=$order_id
    and i.item_state='to_be_shipped'"]
}

# If they select "All items", I want to generate a list of the items because, regardless
# of what happens elsewhere on the site (e.g. an item is added to the order, thereby causing
# the query for all items to return one more item), I want only the items that they confirm
# here to be recorded as part of this shipment.
if { [info exists all_items_p] } {
    set item_id_list [list]
}

set items_to_print ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { [info exists all_items_p] } {
	lappend item_id_list $item_id
    }

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


   append items_to_print "<li> $product_name; [ec_decode $options "" "" "$options; "]$price_name: [ec_pretty_price $price_charged]"
}

ns_write "<form method=post action=fulfill-3.tcl>
[export_form_vars shipment_id order_id item_id_list shipment_date expected_arrival_date carrier tracking_number]
<center>
<input type=submit value=\"Confirm\">
</center>
<blockquote>
Item(s):
<ul>
$items_to_print
</ul>

Shipment information:

<ul>

<li>Shipment date: [ec_formatted_date $shipment_date]

[ec_decode $expected_arrival_date "" "" "<li>Expected arrival date: [ec_formatted_date $expected_arrival_date]"]

[ec_decode $carrier "" "" "<li>Carrier: $carrier"]

[ec_decode $tracking_number "" "" "<li>Tracking Number: $tracking_number"]

</ul>

Ship to:
<br>

<blockquote>

[ec_display_as_html [ec_pretty_mailing_address_from_ec_addresses $db [database_to_tcl_string $db "select shipping_address from ec_orders where order_id=$order_id"]]]

</blockquote>

</blockquote>

<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"