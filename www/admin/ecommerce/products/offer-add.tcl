# $Id: offer-add.tcl,v 3.0 2000/02/06 03:20:21 ron Exp $
set_the_usual_form_variables
# product_id, product_name, retailer_id, price, shipping, stock_status,
# offer_begins & offer_ends (in parts), special_offer_p, special_offer_html
# and possibly shipping_unavailable_p

set exception_count 0
set exception_text ""

set possible_error_list [list [list retailer_id "to pick a retailer"] [list price "to enter the price"] [list special_offer_p "to specify whether this is a special offer"] ]

foreach possible_error $possible_error_list {
    if { ![info exists [lindex $possible_error 0]] || [empty_string_p [set [lindex $possible_error 0]]] } {
	incr exception_count
	append exception_text "<li>You forgot [lindex $possible_error 1]."
    }
}

if { [regexp {[^0-9\.]} $price] } {
    incr exception_count
    append exception_text "<li>The price must be a number."
}

if { [regexp {[^0-9\.]} $shipping] } {
    incr exception_count
    append exception_text "<li>The shipping price must be a number."
}

# either there should be a shipping price or shipping_unavailable_p
# should exist (in which case it will be "t"), but not both
if { ![info exists shipping_unavailable_p] && [empty_string_p $shipping] } {
    incr exception_count
    append exception_text "<li>Please either enter a shipping cost or
    specify that only Pick Up is available.\n"
} elseif { [info exists shipping_unavailable_p] && ![empty_string_p $shipping] } {
    incr exception_count
    append exception_text "<li>You have specified that only Pick Up is available, therefore you must leave the shipping price blank.\n"
}


# deal w/dates
set form [ns_getform]
if [catch  { ns_dbformvalue $form offer_begins date offer_begins} errmsg ] {
    incr exception_count
    append exception_text "<li>The date that the offer begins was specified in the wrong format.  It should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.offer%5fbegins.year]] < 4 } {
    incr exception_count
    append exception_text "<li>The year that the offer begins needs to contain 4 digits.\n"
}


if [catch  { ns_dbformvalue $form offer_ends date offer_ends} errmsg ] {
    incr exception_count
    append exception_text "<li>The date that the offer expires was specified in the wrong format.  It should be in the format Month DD YYYY.\n"
} elseif { [string length [set ColValue.offer%5fends.year]] < 4 } {
    incr exception_count
    append exception_text "<li>The year that the offer expires needs to contain 4 digits.\n"
}

if { [info exists offer_begins] && [empty_string_p $offer_begins] } {
    incr exception_count
    append exception_text "<li>You forgot to enter the date that the offer begins.\n"
}

if { [info exists offer_ends] && [empty_string_p $offer_ends] } {
    incr exception_count
    append exception_text "<li>You forgot to enter the date that the offer expires.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}


# add some times to the dates, so that it starts at the beginning
# of the first day and ends at the end of the last day
set offer_begins "$offer_begins 00:00:00"
set offer_ends "$offer_ends 23:59:59"
set to_date_offer_begins "to_date('$offer_begins','YYYY-MM-DD HH24:MI:SS')"
set to_date_offer_ends "to_date('$offer_ends','YYYY-MM-DD HH24:MI:SS')"


# see if a non-deleted offer for this product and retailer whose
# dates of validity overlap this offer is already in ec_offers, in which
# case they can't add this new offer

set db [ns_db gethandle]

if { [database_to_tcl_string $db "select count(*) from ec_offers
where product_id=$product_id
and retailer_id=$retailer_id
and deleted_p='f'
and (($to_date_offer_begins >= offer_begins and $to_date_offer_begins <= offer_ends) or ($to_date_offer_ends >= offer_begins and $to_date_offer_ends <= offer_ends) or ($to_date_offer_begins <= offer_ends and $to_date_offer_ends >= offer_ends))
"] > 0 } {
    ad_return_complaint 1 "<li>You already have an offer from this retailer for this product whose dates overlap with the dates of this offer.  Please either delete the previous offer before adding this one, or edit the previous offer instead of adding this one.\n"
    return
}


# error checking done

ReturnHeaders
ns_write "[ad_admin_header "Confirm Retailer Offer on $product_name"]

<h2>Confirm Retailer Offer on $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "Confirm Retailer Offer"]

<hr>
"

set currency [ad_parameter Currency ecommerce]

ns_write "<table>
<tr>
<td>Retailer:</td>
<td>[database_to_tcl_string $db "select retailer_name || ' (' || decode(reach,'web',url,city || ', ' || usps_abbrev) || ')'  from ec_retailers where retailer_id=$retailer_id"]</td>
</tr>
<tr>
<td>Price:</td>
<td>[ec_pretty_price $price $currency]</td>
</tr>
<tr>
<td>Shipping:</td>
"
if { [info exists shipping_unavailable_p] } {
    ns_write "<td>Pick Up</td>\n"
} else {
    ns_write "<td>[ec_pretty_price $shipping $currency]</td>\n"
}

ns_write "</tr>
<tr>
<td>Stock Status:</td>
<td>
"    
if { ![empty_string_p $stock_status] } {
    ns_write [ad_parameter "StockMessage[string toupper $stock_status]" ecommerce]
} else {
    ns_write [ec_message_if_null $stock_status]
}
ns_write "</td>
</tr>
<tr>
<td>Offer Begins</td>
<td>[util_AnsiDatetoPrettyDate [ec_date_with_time_stripped $offer_begins]]</td>
</tr>
<tr>
<td>Offer Expires</td>
<td>[util_AnsiDatetoPrettyDate [ec_date_with_time_stripped $offer_ends]]</td>
</tr>
"

if { $special_offer_p == "t" } {
    ns_write "<tr><td>Special Offer:</td><td>$special_offer_html</td></tr>\n"
}

ns_write "</table>
"

set offer_id [database_to_tcl_string $db "select ec_offer_sequence.nextval from dual"]

ns_write "<form method=post action=offer-add-2.tcl>
[export_form_vars offer_id product_id product_name retailer_id price shipping stock_status shipping_unavailable_p offer_begins offer_ends special_offer_p special_offer_html]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"
