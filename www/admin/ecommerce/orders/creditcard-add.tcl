# $Id: creditcard-add.tcl,v 3.0 2000/02/06 03:19:00 ron Exp $
set_the_usual_form_variables
# order_id

ReturnHeaders
ns_write "[ad_admin_header "New Credit Card"]

<h2>New Credit Card</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?[export_url_vars order_id]" "One Order"] "New Credit Card"]

<hr>
Entering a new credit card will cause all future transactions involving this order
to use this credit card.  However, it will not have any effect on transactions that
are currently underway (e.g., if a transaction has already been authorized with a
different credit card, that credit card will be used to complete the transaction).
"

set db [ns_db gethandle]
set zip_code [database_to_tcl_string $db "select zip_code from ec_addresses a, ec_orders o where a.address_id=o.shipping_address and order_id=$order_id"]

ns_write "<form method=post action=creditcard-add-2.tcl>
[export_form_vars order_id]
<blockquote>
<table>
<tr>
<td>Credit card number:</td>
<td><input type=text name=creditcard_number size=17></td>
</tr>
<tr>
<td>Type:</td>
<td>[ec_creditcard_widget]</td>
</tr>
<tr>
<td>Expires:</td>
<td>[ec_creditcard_expire_1_widget] [ec_creditcard_expire_2_widget]</td>
<tr>
<td>Billing zip code:</td>
<td><input type=text name=billing_zip_code value=\"$zip_code\" size=5></td>
</tr>
</table>
</blockquote>

<center>
<input type=submit value=\"Continue\">
</center>

</form>

[ad_admin_footer]
"