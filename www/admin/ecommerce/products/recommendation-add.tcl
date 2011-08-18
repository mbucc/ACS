# $Id: recommendation-add.tcl,v 3.0 2000/02/06 03:20:39 ron Exp $
set_the_usual_form_variables
# product_name_query

set db [ns_db gethandle]
set selection [ns_db select $db "select product_name, product_id
from ec_products
where upper(product_name) like '%[string toupper $QQproduct_name_query]%'"]

set header_to_print "Please choose the product you wish to recommend.
<ul>
"

ReturnHeaders

ns_write "[ad_admin_header "Add a Product Recommendation"]

<h2>Add a Product Recommendation</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "recommendations.tcl" "Recommendations"] "Add One"]

<hr>
"

set header_written_p 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $header_written_p == 0 } {
	ns_write $header_to_print
	incr header_written_p
    }
    ns_write "<li>$product_name \[<a href=\"one.tcl?[export_url_vars product_id]\">view</a> | <a href=\"recommendation-add-2.tcl?[export_url_vars product_name product_id]\">recommend</a>\] ($product_id)\n"
}

if { $header_written_p } {
    ns_write "</ul>"
} else {
    ns_write "No matching products were found."
}

ns_write "[ad_admin_footer]
"
