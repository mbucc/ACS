# $Id: link-add.tcl,v 3.0 2000/02/06 03:20:13 ron Exp $
set_the_usual_form_variables
# product_id, product_name
# either link_product_name or link_product_id

ReturnHeaders
ns_write "[ad_admin_header "Create New Link"]

<h2>Create New Link</h2>

[ad_admin_context_bar [list ../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "New Link"]

<hr>
Please select the product you wish to link to or from:
<ul>
"

if { [info exists link_product_id] } {
    set additional_query_part "product_id='$link_product_id'"
} else {
    set additional_query_part "upper(product_name) like '%[string toupper $link_product_name]%'"
}

set db [ns_db gethandle]
set selection [ns_db select $db "select product_id as link_product_id, product_name as link_product_name from ec_products where $additional_query_part"]

set product_counter 0
while {[ns_db getrow $db $selection]} {
    incr product_counter
    set_variables_after_query
    ns_write "<li><a href=\"link-add-2.tcl?[export_url_vars product_id product_name link_product_id link_product_name]\">$link_product_name</a>\n"
}

if { $product_counter == 0 } {
    ns_write "No matching products were found.\n"
}

ns_write "</ul>

[ad_admin_footer]
"