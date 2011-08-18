# $Id: category-delete.tcl,v 3.0 2000/02/06 03:16:57 ron Exp $
set_the_usual_form_variables
# category_id, category_name

ReturnHeaders

ns_write "[ad_admin_header "Confirm Deletion"]

<h2>Confirm Deletion</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Categories &amp; Subcategories"] [list "category.tcl?[export_url_vars category_id category_name]" $category_name] "Delete this Category"]

<hr>

<form method=post action=category-delete-2.tcl>
[export_form_vars category_id]
Please confirm that you wish to delete the category $category_name.  Please also note the following:
<p>
<ul>
<li>This will delete all subcategories and subsubcategories of the category $category_name.
<li>This will not delete the products in this category (if any).  However, it will cause them to no longer be associated with this category.
<li>This will not delete the templates associated with this category (if any).  However, it will cause them to no longer be associated with this category.
</ul>
<p>
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"
