# $Id: subcategory-delete.tcl,v 3.0 2000/02/06 03:17:08 ron Exp $
set_the_usual_form_variables
# category_id, category_name, subcategory_id, subcategory_name

ReturnHeaders

ns_write "[ad_admin_header "Confirm Deletion"]

<h2>Confirm Deletion</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Categories &amp; Subcategories"] [list "category.tcl?[export_url_vars category_id category_name]" $category_name] [list "subcategory.tcl?[export_url_vars subcategory_id subcategory_name category_id category_name]" $subcategory_name] "Delete this Subcategory"]

<hr>

<form method=post action=subcategory-delete-2.tcl>
[export_form_vars subcategory_id category_id category_name]
Please confirm that you wish to delete the category $category_name.  Please also note the following:
<p>
<ul>
<li>This will delete all subsubcategories of the subcategory $subcategory_name.
<li>This will not delete the products in this subcategory (if any).  However, it will cause them to no longer be associated with this subcategory.
</ul>
<p>
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"
