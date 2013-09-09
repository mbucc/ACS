# /www/admin/ecommerce/orders/items-add-3.tcl
ad_page_contract {

  Add items, Cont.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id items-add-3.tcl,v 3.2.6.4 2001/01/12 19:55:35 khy Exp
} {
  order_id:integer,notnull
  product_id:integer,notnull
  color_choice
  size_choice
  sytle_choice
}

doc_body_append "[ad_admin_header "Add Items, Cont."]

<h2>Add Items, Cont.</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index" "Orders"] [list "one?order_id=$order_id" "One Order"] "Add Items, Cont."]

<hr>
"

set item_id [db_string item_id_select "select ec_item_id_sequence.nextval from dual"]
set user_id [db_string user_id_select "select user_id from ec_orders where order_id=:order_id"]
set lowest_price_and_price_name [ec_lowest_price_and_price_name_for_an_item $product_id $user_id ""]

doc_body_append "<form method=post action=items-add-4>
[export_form_vars order_id product_id color_choice size_choice style_choice]
[export_form_vars -sign item_id]

<blockquote>
This is the price that this user would normally receive for this product.
Make modifications as needed:

<blockquote>
<input type=text name=price_name value=\"[ad_quotehtml [lindex $lowest_price_and_price_name 1]]\" size=15>
<input type=text name=price_charged value=\"[format "%0.2f" [lindex $lowest_price_and_price_name 0]]\" size=4> ([ad_parameter Currency ecommerce])
</blockquote>

</blockquote>

<center>
<input type=submit value=\"Add the Item\">
</center>
</form>

[ad_admin_footer]
"
