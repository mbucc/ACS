#  www/admin/ecommerce/products/link-add-2.tcl
ad_page_contract {
  Link a product.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id link-add-2.tcl,v 3.1.6.1 2000/07/22 07:57:39 ron Exp
} {
  product_id:integer,notnull
  link_product_id:integer,notnull
}

set product_name [ec_product_name $product_id]
set link_product_name [ec_product_name $link_product_id]

doc_body_append "[ad_admin_header "Create New Link, Cont."]

<h2>Create New Link, Cont.</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "New Link, Cont."]

<hr>

Please choose an action:

<ul>

<li><a href=\"link-add-3?action=from&[export_url_vars product_id link_product_id]\">Link <i>to</i> $link_product_name <i>from</i> $product_name</a>

<p>

<li><a href=\"link-add-3?action=to&[export_url_vars product_id link_product_id]\">Link <i>to</i> $product_name <i>from</i> $link_product_name</a>

<p>

<li><a href=\"link-add-3?action=both&[export_url_vars product_id link_product_id]\">Link <i>to</i> $product_name <i>from</i> $link_product_name <i>and</i> vice versa</a>

</ul>

[ad_admin_footer]
"