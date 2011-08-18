# $Id: sale-price-edit.tcl,v 3.0 2000/02/06 03:20:57 ron Exp $
set_the_usual_form_variables
# product_id, product_name, sale_price_id

ReturnHeaders

ns_write "[ad_admin_header "Edit Sale Price for $product_name"]

<h2>Edit Sale Price for $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "Edit Sale Price"]

<hr>
<form method=post action=sale-price-edit-2.tcl>

[export_form_vars product_id product_name sale_price_id]
"

set db [ns_db gethandle]
set selection [ns_db 1row $db "select sale_price, to_char(sale_begins,'YYYY-MM-DD HH24:MI:SS') as sale_begins, to_char(sale_ends,'YYYY-MM-DD HH24:MI:SS') as sale_ends, sale_name, offer_code from ec_sale_prices where sale_price_id=$sale_price_id"]
set_variables_after_query

ns_write "<table>
<tr>
<td>Sale Price</td>
<td><input type=text name=sale_price size=6 value=\"$sale_price\"> (in [ad_parameter Currency ecommerce])</td>
</tr>
<tr>
<td>Name</td>
<td><input type=text name=sale_name size=15 value=\"[philg_quote_double_quotes $sale_name]\"> (like Special Offer or Introductory Price or Sale Price)</td>
</tr>
<tr>
<td>Sale Begins</td>
<td>[ad_dateentrywidget sale_begins [ec_date_with_time_stripped $sale_begins]] [ec_timeentrywidget sale_begins $sale_begins]</td>
</tr>
<tr>
<td>Sale Ends</td>
<td>[ad_dateentrywidget sale_ends [ec_date_with_time_stripped $sale_ends]] [ec_timeentrywidget sale_ends $sale_ends]</td>
</tr>
<tr>
<td>Offer Code</td>
<td><input type=radio name=\"offer_code_needed\" value=\"no\" [ec_decode $offer_code "" "checked" ""]> None needed<br>
<input type=radio name=\"offer_code_needed\" value=\"yes_supplied\" [ec_decode $offer_code "" "" "checked"]> Require this code: 
<input type=text name=\"offer_code\" size=10 maxlength=20 value=\"$offer_code\"><br>
<input type=radio name=\"offer_code_needed\" value=\"yes_generate\"> Please generate a [ec_decode $offer_code "" "" "new "]code
</td>
</tr>
</table>

<p>

<center>
<input type=submit value=\"Submit\">
</center>

</form>

[ad_admin_footer]
"