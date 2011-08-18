# $Id: sale-price-expire.tcl,v 3.0 2000/02/06 03:21:00 ron Exp $
set_the_usual_form_variables
# product_id, product_name, sale_price_id

ReturnHeaders

ns_write "[ad_admin_header "Expire Sale Price for $product_name"]

<h2>Expire Sale Price for $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "Expire Sale Price"]

<hr>

Please confirm that you want to end the sale price right now.

<form method=post action=sale-price-expire-2.tcl>

[export_form_vars product_id product_name sale_price_id]

<p>

<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"