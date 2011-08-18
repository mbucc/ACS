# $Id: subsubcategory.tcl,v 3.0 2000/02/06 03:17:21 ron Exp $
set_the_usual_form_variables
# category_id, category_name, subcategory_id, subcategory_name, subsubcategory_id, subsubcategory_name

ReturnHeaders

ns_write "[ad_admin_header "Subsubcategory: $subsubcategory_name"]

<h2>Subsubcategory: $subsubcategory_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Categories &amp; Subcategories"] [list "category.tcl?[export_url_vars category_id category_name]" $category_name] [list "subcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]" $subcategory_name] "One Subsubcategory"]

<hr>

<ul>

<form method=post action=subsubcategory-edit.tcl>
[export_form_vars category_id category_name subcategory_id subcategory_name subsubcategory_id]
<li>Change subsubcategory name to:
<input type=text name=subsubcategory_name size=30 value=\"[philg_quote_double_quotes $subsubcategory_name]\">
<input type=submit value=\"Change\">
</form>

<p>

<li><a href=\"../products/one-subsubcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name subsubcategory_id subsubcategory_name]\">View all products in this subsubcategory</a>

<p>

<li><a href=\"subsubcategory-delete.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name subsubcategory_id subsubcategory_name]\">Delete this subsubcategory</a>

<p>
"

# Set audit variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables
set audit_name "$subsubcategory_name"
set audit_id $subsubcategory_id
set audit_id_column "subsubcategory_id"
set return_url "subsubcategory.tcl?[export_url_vars subsubcategory_id subsubcategory_name]"
set audit_tables [list ec_subsubcategories_audit ec_subsubcat_prod_map_audit]
set main_tables [list ec_subsubcategories ec_subsubcategory_product_map]

ns_write "<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Trail</a>

</ul>

[ad_admin_footer]
"






