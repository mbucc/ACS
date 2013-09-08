#  www/admin/ecommerce/products/recommendation-add.tcl
ad_page_contract {
  Search for a product to recommend.

  @author eveander@arsdigita.com
  @creation-date Summer 1999
  @cvs-id recommendation-add.tcl,v 3.1.6.2 2000/07/22 07:57:41 ron Exp
} {
  product_name_query
}

set header_to_print "Please choose the product you wish to recommend.
<ul>
"
doc_body_append "[ad_admin_header "Add a Product Recommendation"]

<h2>Add a Product Recommendation</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "recommendations.tcl" "Recommendations"] "Add One"]

<hr>
"

set header_written_p 0
db_foreach product_search_select "
select product_name, product_id
from ec_products
where upper(product_name) like '%' || upper(:product_name_query) || '%'
" {
  if { $header_written_p == 0 } {
    doc_body_append $header_to_print
    incr header_written_p
  }
  doc_body_append "<li>$product_name \[<a href=\"one?[export_url_vars product_id]\">view</a> | <a href=\"recommendation-add-2?[export_url_vars product_name product_id]\">recommend</a>\] ($product_id)\n"
}

if { $header_written_p } {
  doc_body_append "</ul>"
} else {
  doc_body_append "No matching products were found."
}

doc_body_append "[ad_admin_footer]
"
