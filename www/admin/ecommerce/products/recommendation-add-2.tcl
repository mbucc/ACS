#  www/admin/ecommerce/products/recommendation-add-2.tcl
ad_page_contract {
  Recommend a product.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id recommendation-add-2.tcl,v 3.1.6.2 2000/07/22 07:57:41 ron Exp
} {
  product_id:integer,notnull
}

set product_name [ec_product_name $product_id]

doc_body_append "[ad_admin_header "Add a Product Recommendation"]

<h2>Add a Product Recommendation</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "recommendations.tcl" "Recommendations"] "Add One"]

<hr>

<form method=post action=\"recommendation-add-3\">
[export_form_vars product_id]

<table>
<tr>
<td>Product:</td>
<td>$product_name</td>
</tr>
<tr>
<td>Recommended For:</td>
<td>[ec_user_class_widget]</td>
</tr>
<tr>
<td>Display Recommendation In:</td>
<td>[ec_category_widget "f" "" "t"]</td>
</tr>
<tr>
<td>Accompanying Text<br>(HTML format):</td>
<td><textarea wrap name=recommendation_text rows=6 cols=40></textarea></td>
</tr>
</table>

<center>
<input type=submit value=\"Submit\">
</center>

</form>

[ad_admin_footer]
"
