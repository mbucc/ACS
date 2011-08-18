# $Id: items-add-3.tcl,v 3.1 2000/03/07 04:40:16 eveander Exp $
set_the_usual_form_variables
# order_id, product_id, color_choice, size_choice, style_choice

ReturnHeaders
ns_write "[ad_admin_header "Add Items, Cont."]

<h2>Add Items, Cont.</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?order_id=$order_id" "One Order"] "Add Items, Cont."]

<hr>
"

set db [ns_db gethandle]
set item_id [database_to_tcl_string $db "select ec_item_id_sequence.nextval from dual"]
set user_id [database_to_tcl_string $db "select user_id from ec_orders where order_id=$order_id"]
set lowest_price_and_price_name [ec_lowest_price_and_price_name_for_an_item $db $product_id $user_id ""]

ns_write "<form method=post action=items-add-4.tcl>
[export_form_vars order_id product_id color_choice size_choice style_choice item_id]

<blockquote>
This is the price that this user would normally receive for this product.
Make modifications as needed:

<blockquote>
<input type=text name=price_name value=\"[philg_quote_double_quotes [lindex $lowest_price_and_price_name 1]]\" size=15>
<input type=text name=price_charged value=\"[format "%0.2f" [lindex $lowest_price_and_price_name 0]]\" size=4> ([ad_parameter Currency ecommerce])
</blockquote>

</blockquote>

<center>
<input type=submit value=\"Add the Item\">
</center>
</form>

[ad_admin_footer]
"