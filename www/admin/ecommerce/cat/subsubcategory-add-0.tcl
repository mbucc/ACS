# $Id: subsubcategory-add-0.tcl,v 3.0 2000/02/06 03:17:13 ron Exp $
set_the_usual_form_variables
# category_id, category_name, subcategory_id, subcategory_name, prev_sort_key, next_sort_key

# error checking: make sure that there is no subsubcategory in this subcategory
# with a sort key equal to the new sort key
# (average of prev_sort_key and next_sort_key);
# otherwise warn them that their form is not up-to-date

set db [ns_db gethandle]
set n_conflicts [database_to_tcl_string $db "select count(*)
from ec_subsubcategories
where subcategory_id=$subcategory_id
and sort_key = ($prev_sort_key + $next_sort_key)/2"]

if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The page you came from appears to be out-of-date;
    perhaps someone has changed the subsubcategories since you last reloaded the page.
    Please go back to the previous page, push \"reload\" or \"refresh\" and try
    again."
    return
}


ReturnHeaders

ns_write "[ad_admin_header "Add a New Subsubcategory"]

<h2>Add a New Subsubcategory</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Categories"] [list "category.tcl?[export_url_vars category_id category_name]" $category_name] [list "subcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name]" $subcategory_name] "Add a New Subsubcategory"]

<hr>

<ul>

<form method=post action=subsubcategory-add.tcl>
[export_form_vars category_id category_name subcategory_id subcategory_name prev_sort_key next_sort_key]
Name: <input type=text name=subsubcategory_name size=30>
<input type=submit value=\"Add\">
</form>

</ul>

[ad_admin_footer]
"