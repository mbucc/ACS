# $Id: category.tcl,v 3.0 2000/02/06 03:17:01 ron Exp $
set_the_usual_form_variables
# category_id, category_name

ReturnHeaders

ns_write "[ad_admin_header "Category: $category_name"]

<h2>Category: $category_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Categories &amp; Subcategories"] "One Category"]

<hr>

<ul>

<form method=post action=category-edit.tcl>
[export_form_vars category_id]
<li>Change category name to:
<input type=text name=category_name size=30 value=\"[philg_quote_double_quotes $category_name]\">
<input type=submit value=\"Change\">
</form>

<p>

<li><a href=\"../products/list.tcl?[export_url_vars category_id]\">View all products in this category</a>

<p>

<li><a href=\"category-delete.tcl?[export_url_vars category_id category_name]\">Delete this category</a>

<p>
"

# Set audit variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables
set audit_name "$category_name"
set audit_id $category_id
set audit_id_column "category_id"
set return_url "category.tcl?[export_url_vars category_id category_name]"
set audit_tables [list ec_categories_audit ec_subcategories_audit ec_category_product_map_audit]
set main_tables [list ec_categories ec_subcategories ec_category_product_map]

ns_write "<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Trail</a>

</ul>

<p>

<h3>Current Subcategories of $category_name</h3>

<blockquote>
<table>
"

set db [ns_db gethandle]
set selection [ns_db select $db "select subcategory_id, sort_key, subcategory_name from ec_subcategories where category_id=$category_id order by sort_key"]

set old_subcategory_id ""
set old_sort_key ""
set subcategory_counter 0

while { [ns_db getrow $db $selection] } {
    incr subcategory_counter
    set_variables_after_query
    if { ![empty_string_p $old_subcategory_id] } {
	ns_write "<td> &nbsp;&nbsp;<font face=\"MS Sans Serif, arial,helvetica\"  size=1><a href=\"subcategory-add-0.tcl?[export_url_vars category_id category_name]&prev_sort_key=$old_sort_key&next_sort_key=$sort_key\">insert after</a> &nbsp;&nbsp; <a href=\"subcategory-swap.tcl?[export_url_vars category_id category_name]&subcategory_id=$old_subcategory_id&next_subcategory_id=$subcategory_id&sort_key=$old_sort_key&next_sort_key=$sort_key\">swap with next</a></font></td></tr>"
    }
    set old_subcategory_id $subcategory_id
    set old_sort_key $sort_key
    ns_write "<tr><td>$subcategory_counter. <a href=\"subcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]\">$subcategory_name</a></td>\n"
}

if { $subcategory_counter != 0 } {
    ns_write "<td> &nbsp;&nbsp;<font face=\"MS Sans Serif, arial,helvetica\"  size=1><a href=\"subcategory-add-0.tcl?[export_url_vars category_id category_name]&prev_sort_key=$old_sort_key&next_sort_key=[expr $old_sort_key + 2]\">insert after</a></font></td></tr>
    "
} else {
    ns_write "You haven't set up any subcategories.  <a href=\"subcategory-add-0.tcl?[export_url_vars category_id category_name]&prev_sort_key=1&next_sort_key=2\">Add a subcategory.</a>\n"
}

ns_write "
</table>
</blockquote>

[ad_admin_footer]
"
