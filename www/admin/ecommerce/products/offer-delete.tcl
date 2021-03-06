#  www/admin/ecommerce/products/offer-delete.tcl
ad_page_contract {
  Delete or undelete an offer.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id offer-delete.tcl,v 3.1.6.1 2000/07/22 07:57:40 ron Exp
} {
  deleted_p
  product_id:integer,notnull
  retailer_id:integer,notnull
}

set product_name [ec_product_name $product_id]

if { $deleted_p == "t" } {
    set delete_or_undelete "Delete"
    set deletion_or_undeletion "Deletion"
} else {
    set delete_or_undelete "Undelete"
    set deletion_or_undeletion "Undeletion"
}

doc_body_append "[ad_admin_header "Confirm $deletion_or_undeletion of Retailer Offer on $product_name"]

<h2>Confirm $deletion_or_undeletion of Retailer Offer on $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "$delete_or_undelete Retailer Offer"]

<hr>
"

doc_body_append "<form method=post action=offer-delete-2>
[export_form_vars deleted_p product_id retailer_id]

<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"
