# $Id: offer-delete.tcl,v 3.0 2000/02/06 03:20:24 ron Exp $
set_the_usual_form_variables
# deleted_p, product_id, product_name, retailer_id

if { $deleted_p == "t" } {
    set delete_or_undelete "Delete"
    set deletion_or_undeletion "Deletion"
} else {
    set delete_or_undelete "Undelete"
    set deletion_or_undeletion "Undeletion"
}

ReturnHeaders
ns_write "[ad_admin_header "Confirm $deletion_or_undeletion of Retailer Offer on $product_name"]

<h2>Confirm $deletion_or_undeletion of Retailer Offer on $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "$delete_or_undelete Retailer Offer"]

<hr>
"

ns_write "<form method=post action=offer-delete-2.tcl>
[export_form_vars deleted_p product_id product_name retailer_id]

<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"
