# $Id: link-delete.tcl,v 3.0 2000/02/06 03:20:15 ron Exp $
set_the_usual_form_variables
# product_a, product_b, product_id, product_name, rowid

ReturnHeaders
ns_write "[ad_admin_header "Confirm Deletion"]

<h2>Confirm Deletion</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "Delete Link"]

<hr>
Please confirm that you wish to delete this link.

<form method=post action=link-delete-2.tcl>

[export_form_vars product_id product_name product_a product_b]

<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"
