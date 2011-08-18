# $Id: link-add-2.tcl,v 3.0 2000/02/06 03:20:10 ron Exp $
set_the_usual_form_variables
# product_id, product_name, link_product_name, link_product_id

ReturnHeaders
ns_write "[ad_admin_header "Create New Link, Cont."]

<h2>Create New Link, Cont.</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "New Link, Cont."]

<hr>

Please choose an action:

<ul>

<li><a href=\"link-add-3.tcl?action=from&[export_url_vars product_id product_name link_product_id link_product_name]\">Link <i>to</i> $link_product_name <i>from</i> $product_name</a>

<p>

<li><a href=\"link-add-3.tcl?action=to&[export_url_vars product_id product_name link_product_id link_product_name]\">Link <i>to</i> $product_name <i>from</i> $link_product_name</a>

<p>

<li><a href=\"link-add-3.tcl?action=both&[export_url_vars product_id product_name link_product_id link_product_name]\">Link <i>to</i> $product_name <i>from</i> $link_product_name <i>and</i> vice versa</a>

</ul>

[ad_admin_footer]
"