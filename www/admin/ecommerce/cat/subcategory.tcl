# $Id: subcategory.tcl,v 3.0 2000/02/06 03:17:11 ron Exp $
set_the_usual_form_variables
# category_id, category_name, subcategory_id, subcategory_name

ReturnHeaders

ns_write "[ad_admin_header "Subcategory: $subcategory_name"]

<h2>Subcategory: $subcategory_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Categories &amp; Subcategories"] [list "category.tcl?[export_url_vars category_id category_name]" $category_name] "One Subcategory"]

<hr>

<ul>

<form method=post action=subcategory-edit.tcl>
[export_form_vars category_id category_name subcategory_id]
<li>Change subcategory name to:
<input type=text name=subcategory_name size=30 value=\"[philg_quote_double_quotes $subcategory_name]\">
<input type=submit value=\"Change\">
</form>

<p>

<li><a href=\"../products/one-subcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]\">View all products in this subcategory</a>

<p>

<li><a href=\"subcategory-delete.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]\">Delete this subcategory</a>

<p>
"

# Set audit variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables
set audit_name "$subcategory_name"
set audit_id $subcategory_id
set audit_id_column "subcategory_id"
set return_url "subcategory.tcl?[export_url_vars subcategory_id subcategory_name]"
set audit_tables [list ec_subcategories_audit ec_subsubcategories_audit ec_subcat_prod_map_audit]
set main_tables [list ec_subcategories ec_subsubcategories ec_subcategory_product_map]

ns_write "<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Trail</a>

</ul>

<h3>Current Subsubcategories of $subcategory_name</h3>

<table>
"

set db [ns_db gethandle]
set selection [ns_db select $db "select subsubcategory_id, sort_key, subsubcategory_name from ec_subsubcategories where subcategory_id=$subcategory_id order by sort_key"]

set old_subsubcategory_id ""
set old_sort_key ""
set subsubcategory_counter 0

while { [ns_db getrow $db $selection] } {
    incr subsubcategory_counter
    set_variables_after_query
    if { ![empty_string_p $old_subsubcategory_id] } {
	ns_write "<td> &nbsp;&nbsp;<font face=\"MS Sans Serif, arial,helvetica\"  size=1><a href=\"subsubcategory-add-0.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]&prev_sort_key=$old_sort_key&next_sort_key=$sort_key\">insert after</a> &nbsp;&nbsp; <a href=\"subsubcategory-swap.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]&subsubcategory_id=$old_subsubcategory_id&next_subsubcategory_id=$subsubcategory_id&sort_key=$old_sort_key&next_sort_key=$sort_key\">swap with next</a></font></td></tr>"
    }
    set old_subsubcategory_id $subsubcategory_id
    set old_sort_key $sort_key
    ns_write "<tr><td>$subsubcategory_counter. <a href=\"subsubcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name subsubcategory_id subsubcategory_name]\">$subsubcategory_name</a></td>\n"
}

if { $subsubcategory_counter != 0 } {
    ns_write "<td> &nbsp;&nbsp;<font face=\"MS Sans Serif, arial,helvetica\"  size=1><a href=\"subsubcategory-add-0.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]&prev_sort_key=$old_sort_key&next_sort_key=[expr $old_sort_key + 2]\">insert after</a></font></td></tr>
    "
} else {
    ns_write "You haven't set up any subsubcategories.  <a href=\"subsubcategory-add-0.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]&prev_sort_key=1&next_sort_key=2\">Add a subsubcategory.</a>\n"
}


ns_write "</table>
[ad_admin_footer]
"






