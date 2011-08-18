# $Id: recommendation-add-2.tcl,v 3.0 2000/02/06 03:20:34 ron Exp $
set_the_usual_form_variables
#product_id product_name

ReturnHeaders

ns_write "[ad_admin_header "Add a Product Recommendation"]

<h2>Add a Product Recommendation</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "recommendations.tcl" "Recommendations"] "Add One"]

<hr>

<form method=post action=\"recommendation-add-3.tcl\">
[export_form_vars product_id product_name]

<table>
<tr>
<td>Product:</td>
<td>$product_name</td>
</tr>
<tr>
<td>Recommended For:</td>
"
set db [ns_db gethandle]

ns_write "<td>[ec_user_class_widget $db]</td>
</tr>
<tr>
<td>Display Recommendation In:</td>
<td>[ec_category_widget $db "f" "" "t"]</td>
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
