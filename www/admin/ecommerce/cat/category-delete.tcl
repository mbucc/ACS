# /www/admin/ecommerce/cat/category-delete.tcl

ad_page_contract {

    @param category_id the ID of the category to delete
    @param category_name the name of the category to delete

    @cvs-id category-delete.tcl,v 3.1.6.4 2000/09/22 01:34:47 kevin Exp
} {
    category_id:integer,notnull
    category_name:notnull
}


set page_html "[ad_admin_header "Confirm Deletion"]

<h2>Confirm Deletion</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index" "Categories &amp; Subcategories"] [list "category?[export_url_vars category_id category_name]" $category_name] "Delete this Category"]

<hr>

<form method=post action=category-delete-2>
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

doc_return  200 text/html $page_html
