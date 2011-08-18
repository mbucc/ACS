# $Id: search.tcl,v 3.0 2000/02/06 03:21:02 ron Exp $
set_the_usual_form_variables

# product_id or product_name

if { [info exists product_id] } {
    set additional_query_part "product_id=[ns_dbquotevalue $product_id number]"
    set description "Products with id #$product_id:"
} else {
    set additional_query_part "upper(product_name) like '%[string toupper $QQproduct_name]%'"
    set description "Products whose name includes \"$product_name\":"
}

ReturnHeaders

ns_write "[ad_admin_header "Product Search"]

<h2>Product Search</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Product Search"]

<hr>

$description

<ul>
"


set db [ns_db gethandle]
set selection [ns_db select $db "select product_id, product_name from ec_products where $additional_query_part"]

set product_counter 0
while {[ns_db getrow $db $selection]} {
    incr product_counter
    set_variables_after_query
    ns_write "<li><a href=\"one.tcl?[export_url_vars product_id]\">$product_name</a>\n"
}

if { $product_counter == 0 } {
    ns_write "No matching products were found.\n"
}

ns_write "</ul>


[ad_admin_footer]
"
