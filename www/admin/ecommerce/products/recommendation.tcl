# $Id: recommendation.tcl,v 3.0 2000/02/06 03:20:45 ron Exp $
set_the_usual_form_variables

# recommendation_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "select r.*, p.product_name
from  ec_recommendations_cats_view r, ec_products p
where recommendation_id=$recommendation_id
and r.product_id=p.product_id"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "Product Recommendation"]

<h2>Product Recommendation</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "recommendations.tcl" "Recommendations"] "One"]

<hr>

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
    ns_write "<td>[database_to_tcl_string $db "select user_class_name from ec_user_classes where user_class_id=$user_class_id"]</td>
    "
} else {
    ns_write "<td>All Users</td>
    "
}
ns_write "</tr>
<tr>
<td>Display Recommendation In:</td>
"
if { [empty_string_p $the_category_id] && [empty_string_p $the_subcategory_id] && [empty_string_p $the_subsubcategory_id] } {
    ns_write "<td>Top Level</td>"
} else {
    ns_write "<td>[ec_category_subcategory_and_subsubcategory_display $db $the_category_id $the_subcategory_id $the_subsubcategory_id]</td>"
}

ns_write "</tr>
<tr>
<td valign=top>Accompanying Text<br>(HTML format):</td>
<td valign=top>$recommendation_text
<p>
(<a href=\"recommendation-text-edit.tcl?[export_url_vars recommendation_id]\">edit</a>)
</td>
</tr>
</table>

</blockquote>
"

# Set audit variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables
set audit_name Recommendation
set audit_id $recommendation_id
set audit_id_column "recommendation_id"
set return_url "[ns_conn url]?[export_url_vars product_id]"
set audit_tables [list ec_product_recommend_audit]
set main_tables [list ec_product_recommendations]

ns_write "
<ul>
<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Trail</a>

<p>

<li><a href=\"recommendation-delete.tcl?[export_url_vars recommendation_id]\">Delete</a>

</ul>

[ad_admin_footer]
"
