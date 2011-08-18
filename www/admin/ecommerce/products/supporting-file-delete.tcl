# $Id: supporting-file-delete.tcl,v 3.0 2000/02/06 03:21:05 ron Exp $
set_the_usual_form_variables
# dirname file product_id product_name

ReturnHeaders
ns_write "[ad_admin_header "Delete Supporting File for $product_name"]

<h2>Delete Supporting File for $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "Delete Supporting File"]

<hr>

Please confirm that you wish to delete this file.
"

if { $file == "product-thumbnail.jpg" } {
    ns_write "Note: this file is the thumbnail picture of the product.  If you delete it, the customer will not be able to see what the product looks like."
}

ns_write "<form method=post action=supporting-file-delete-2.tcl>
[export_form_vars dirname file product_id]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"