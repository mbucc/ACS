#  www/admin/ecommerce/products/recommendation-add-3.tcl
ad_page_contract {
  Recommend a product.

  @author eveander@arsdigita.com
  @creation-date Summer 1999
  @cvs-id recommendation-add-3.tcl,v 3.2.2.3 2001/01/12 18:47:37 khy Exp
} {
  product_id:integer,notnull
  user_class_id:integer
  recommendation_text:html
  categorization
}

set product_name [ec_product_name $product_id]

# deal w/categorization for display purposes
set category_list [list]
set subcategory_list [list]
set subsubcategory_list [list]
for { set counter 0 } { $counter < [llength $categorization] } {incr counter} {
    if { $counter == 0 } {
	lappend category_list [lindex $categorization 0]
    }
    if { $counter == 1 } {
	lappend subcategory_list [lindex $categorization 1]
    }
    if { $counter == 2 } {
	lappend subsubcategory_list [lindex $categorization 2]
    }
}


set recommendation_id [db_string recommendation_id_select "select ec_recommendation_id_sequence.nextval from dual"]    

doc_body_append "[ad_admin_header "Confirm Product Recommendation"]

<h2>Confirm Product Recommendation</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "recommendations.tcl" "Recommendations"] "Add One"]

<hr>

Please confirm your product recommendation:

<blockquote>

<table cellpadding=10>
<tr>
<td>Product:</td>
<td>$product_name</td>
</tr>
<tr>
<td>Recommended For:</td>
"
if { ![empty_string_p $user_class_id] } {
    doc_body_append "<td>[db_string user_class_select "select user_class_name from ec_user_classes where user_class_id=:user_class_id"]</td>
    "
} else {
    doc_body_append "<td>All Users</td>
    "
}
doc_body_append "</tr>
<tr>
<td>Display Recommendation In:</td>
"
if { [empty_string_p $categorization] } {
    doc_body_append "<td>Top Level</td>"
} else {
    doc_body_append "<td>[ec_category_subcategory_and_subsubcategory_display $category_list $subcategory_list $subsubcategory_list]</td>"
}

doc_body_append "</tr>
<tr>
<td>Accompanying Text<br>(HTML format):</td>
<td>$recommendation_text</td>
</tr>
</table>

</blockquote>

<form method=post action=\"recommendation-add-4\">
[export_form_vars product_id product_name user_class_id recommendation_text categorization]
[export_form_vars -sign recommendation_id]
<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"
