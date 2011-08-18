# $Id: one-subcategory.tcl,v 3.0 2000/02/06 03:20:30 ron Exp $
set_the_usual_form_variables
# category_id, category_name, subcategory_id, subcategory_name

ReturnHeaders

ns_write "[ad_admin_header "Products in $category_name: $subcategory_name"]

<h2>Products in $category_name: $subcategory_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Products in $category_name: $subcategory_name"]

<hr>

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select m.product_id, p.product_name
from ec_subcategory_product_map m, ec_products p
where m.product_id = p.product_id
and m.subcategory_id=$subcategory_id
order by product_name"]

set product_counter 0
while { [ns_db getrow $db $selection] } {
    incr product_counter
    set_variables_after_query
    ns_write "<li><a href=\"one.tcl?[export_url_vars product_id]\">$product_name</a>\n"
}

if { $product_counter == 0 } {
    ns_write "There are no products in this subcategory.\n"
}

ns_write "</ul>

[ad_admin_footer]
"
