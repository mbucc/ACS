# $Id: offer-edit.tcl,v 3.0 2000/02/06 03:20:28 ron Exp $
set_the_usual_form_variables
# offer_id, product_id, product_name, retailer_id

ReturnHeaders
ns_write "[ad_admin_header "Edit Retailer Offer on $product_name"]

<h2>Edit Retailer Offer on $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "Edit Retailer Offer"]

<hr>
"

set old_retailer_id $retailer_id

ns_write "<form method=post action=offer-edit-2.tcl>
[export_form_vars offer_id product_id product_name old_retailer_id]

<table>
<tr>
<td>
Retailer
</td>
<td>
<select name=retailer_id>
<option value=\"\">Pick One
"
set db [ns_db gethandle]
set selection [ns_db select $db "select retailer_name, retailer_id, city, usps_abbrev from ec_retailers order by retailer_name"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $retailer_id == $old_retailer_id } {
	ns_write "<option value=$retailer_id selected>$retailer_name ($city, $usps_abbrev)\n"
    } else {
	ns_write "<option value=$retailer_id>$retailer_name ($city, $usps_abbrev)\n"
    }
}

set selection [ns_db 1row $db "select price, shipping, stock_status, shipping_unavailable_p, offer_begins, offer_ends, special_offer_p, special_offer_html from ec_offers where offer_id=$offer_id"]
set_variables_after_query

set currency [ad_parameter Currency ecommerce]

ns_write "</select>
</td>
</tr>
<tr>
<td>Price</td>
<td><input type=text name=price size=6 value=\"$price\"> (in $currency)</td>
</tr>
<tr>
<td>Shipping</td>
<td><input type=text name=shipping size=6 value=\"$shipping\"> (in $currency) 
&nbsp;&nbsp;<b>or</b>&nbsp;&nbsp;
<input type=checkbox name=shipping_unavailable_p value=\"t\""

if { $shipping_unavailable_p == "t" } {
    ns_write " checked "
}

ns_write ">
Pick Up only
</td>
</tr>
<tr>
<td>Stock Status</td>
<td>[ec_stock_status_widget $stock_status]</td>
</tr>
<tr>
<td>Offer Begins</td>
<td>[ad_dateentrywidget offer_begins $offer_begins]</td>
</tr>
<tr>
<td>Offer Expires</td>
<td>[ad_dateentrywidget offer_ends $offer_ends]</td>
</tr> 
<tr>
<td colspan=2>Is this a Special Offer?
<input type=radio name=special_offer_p value=\"t\""

if { $special_offer_p == "t" } {
    ns_write " checked "
}

ns_write ">Yes &nbsp; 
<input type=radio name=special_offer_p value=\"f\""

if { $special_offer_p == "f" } {
    ns_write " checked "
}

ns_write ">No
</td>
</tr>
<tr>
<td>If yes, elaborate:</td>
<td><textarea wrap name=special_offer_html rows=2 cols=40>$special_offer_html</textarea></td>
</tr>
</table>

<center>
<input type=submit value=\"Edit\">
</center>

</form>

[ad_admin_footer]
"
