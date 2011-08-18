# $Id: offers.tcl,v 3.0 2000/02/06 03:20:29 ron Exp $
set_the_usual_form_variables
# product_id, product_name

proc ec_write_out_one_offer {} {
    uplevel {
	ns_write "<li><a href=\"retailer.tcl?retailer_id=$retailer_id\">$retailer_name</a><br>
	Price: [ec_message_if_null [ec_pretty_price $price $currency]]<br>
	Shipping: 
	"
	if { $shipping_unavailable_p != "t" } {
	    ns_write "[ec_message_if_null [ec_pretty_price $shipping $currency]]<br>"
	} else {
	    ns_write "Pick Up<br>"
	}
	ns_write "Stock Status: "
	if { ![empty_string_p $stock_status] } {
	    ns_write "[ad_parameter "StockMessage[string toupper $stock_status]" ecommerce]<br>\n"
	} else {
	    ns_write "[ec_message_if_null $stock_status]<br>\n"
	}
	ns_write "Offer Begins: [util_AnsiDatetoPrettyDate $offer_begins]<br>
	Offer Expires: [util_AnsiDatetoPrettyDate $offer_ends]<br>
	"
	if { $special_offer_p == "t" } {
	    ns_write "Special Offer: $special_offer_html<br>\n"
	}

	if { $deleted_p == "t" } {
	    ns_write "<b>This offer is deleted.</b><br>\n"
	} elseif { !$offer_begun_p } {
	    ns_write "<b>This offer has not yet begun.</b><br>\n"
	} elseif { $offer_expired_p } {
	    ns_write "<b>This offer has expired.</b><br>\n"
	}

	ns_write "\[<a href=\"offer-edit.tcl?[export_url_vars offer_id product_id product_name retailer_id]\">edit</a> | <a href=\"offer-delete.tcl?deleted_p="
	if { $deleted_p == "t" } {
	    ns_write "f"
	} else {
	    ns_write "t"
	}

	ns_write "&[export_url_vars product_id product_name retailer_id]\">"
	
	if { $deleted_p == "t" } {
	    ns_write "un"
	}

	# Set audit variables
	# audit_name, id, id_column, return_url, audit_tables, main_tables
	set audit_name "$product_name Offer"
	set id $offer_id
	set id_column "offer_id"
	set return_url "offers.tcl?[export_url_vars product_id product_name]"
	set audit_tables [list ec_offers_audit]	
	set main_tables [list ec_offers]

	ns_write "delete</a> | <a href=\"audit.tcl?[export_url_vars audit_name id id_column return_url audit_tables main_tables]\">audit trail</a>\]
	<p>
	"
    }
}

ReturnHeaders
ns_write "[ad_admin_header "Retailer Offers on $product_name"]

<h2>Retailer Offers on $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "Retailer Offers"]

<hr>
<h3>Current Offers</h3>
<ul>
"
set currency [ad_parameter Currency ecommerce]

set db [ns_db gethandle]

set selection [ns_db select $db "select o.offer_id, o.retailer_id, r.retailer_name, price, shipping, stock_status, special_offer_p, special_offer_html, shipping_unavailable_p, offer_begins, offer_ends, o.deleted_p, decode(sign(sysdate-offer_begins),1,1,0) as offer_begun_p, decode(sign(sysdate-offer_ends),1,1,0) as offer_expired_p
from ec_offers_current o, ec_retailers r
where o.retailer_id=r.retailer_id
and o.product_id=$product_id
order by o.last_modified desc"]

set offer_counter 0
while { [ns_db getrow $db $selection] } {
    incr offer_counter
    set_variables_after_query
    ec_write_out_one_offer
}

if { $offer_counter == 0 } {
    ns_write "There are no current offers.\n"
}

ns_write "</ul>

<p>

<h3>Add an Offer</h3>

<form method=post action=offer-add.tcl>
[export_form_vars product_id product_name]

<table>
<tr>
<td>
Retailer
</td>
<td>
<select name=retailer_id>
<option value=\"\">Pick One
"
set selection [ns_db select $db "select retailer_name, retailer_id, decode(reach,'web',url,city || ', ' || usps_abbrev) as location from ec_retailers order by retailer_name"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<option value=$retailer_id>$retailer_name ($location)\n"
}

ns_write "</select>
</td>
</tr>
<tr>
<td>Price</td>
<td><input type=text name=price size=6> (in $currency)</td>
</tr>
<tr>
<td>Shipping</td>
<td><input type=text name=shipping size=6> (in $currency) 
&nbsp;&nbsp;<b>or</b>&nbsp;&nbsp;
<input type=checkbox name=shipping_unavailable_p value=\"t\">
Pick Up only
</td>
</tr>
<tr>
<td>Stock Status</td>
<td>[ec_stock_status_widget]</td>
</tr>
<tr>
<td>Offer Begins</td>
<td>[ad_dateentrywidget offer_begins]</td>
</tr>
<tr>
<td>Offer Expires</td>
<td>[ad_dateentrywidget offer_ends]</td>
</tr> 
<tr>
<td colspan=2>Is this a Special Offer?
<input type=radio name=special_offer_p value=\"t\">Yes &nbsp; 
<input type=radio name=special_offer_p value=\"f\" checked>No
</td>
</tr>
<tr>
<td>If yes, elaborate:</td>
<td><textarea wrap name=special_offer_html rows=2 cols=40></textarea></td>
</tr>
</table>

<p>

<center>
<input type=submit value=\"Add\">
</center>

</form>

<p>

<h3>Non-Current or Deleted Offers</h3>

<ul>
"
set currency [ad_parameter Currency ecommerce]

set selection [ns_db select $db "select o.offer_id, o.retailer_id, retailer_name, price, shipping, stock_status, special_offer_p, special_offer_html, shipping_unavailable_p, offer_begins, offer_ends, o.deleted_p, decode(sign(sysdate-offer_begins),1,1,0) as offer_begun_p, decode(sign(sysdate-offer_ends),1,1,0) as offer_expired_p
from ec_offers o, ec_retailers r
where o.retailer_id=r.retailer_id
and o.product_id=$product_id
and (o.deleted_p='t' or o.offer_begins - sysdate > 0 or o.offer_ends - sysdate < 0)
order by o.last_modified desc"]

set offer_counter 0
while { [ns_db getrow $db $selection] } {
    incr offer_counter
    set_variables_after_query
    ec_write_out_one_offer
}

if { $offer_counter == 0 } {
    ns_write "There are no non-current or deleted offers.\n"
}

ns_write "</ul>

[ad_admin_footer]
"