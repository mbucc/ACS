# $Id: delete.tcl,v 3.0 2000/02/06 03:20:02 ron Exp $
set_the_usual_form_variables
# product_id, product_name

ReturnHeaders
ns_write "[ad_admin_header "Confirm Deletion of $product_name"]

<h2>Confirm Deletion</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" "One"] "Confirm Deletion"]

<hr>

Are you sure you want to delete $product_name?  Note that the system
will not let you delete a product if anyone has already ordered it
(you might want to mark the product \"discontinued\" instead).

<p>
<form method=post action=delete-2.tcl>
[export_form_vars product_id product_name]
<center>
<input type=submit value=\"Yes\">
</center>
</form>

[ad_admin_footer]
"
