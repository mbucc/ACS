# /www/admin/ecommerce/cat/subcategory-add-0.tcl

ad_page_contract {

    @param category_id the ID of the category
    @param category_name the name of the category
    @param prev_sort_key the previous sort key
    @param next_sort_key the next sort key

    @cvs-id subcategory-add-0.tcl,v 3.1.6.7 2000/09/22 01:34:48 kevin Exp
} {

    category_id:integer,notnull
    category_name:trim,notnull
    prev_sort_key:notnull
    next_sort_key:notnull
}

# error checking: make sure that there is no subcategory in this category
# with a sort key equal to the new sort key
# (average of prev_sort_key and next_sort_key);
# otherwise warn them that their form is not up-to-date


set n_conflicts [db_string get_n_conflicts "select count(*)
from ec_subcategories
where category_id=:category_id
and sort_key = (:prev_sort_key + :next_sort_key)/2"]

if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The page you came from appears to be out-of-date;
    perhaps someone has changed the subcategories since you last reloaded the page.
    Please go back to the previous page, push \"reload\" or \"refresh\" and try
    again."
    return
}


set page_html "[ad_admin_header "Add a New Subcategory"]

<h2>Add a New Subcategory</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index" "Product Categories"] [list "category?[export_url_vars category_id category_name]" $category_name] "Add a New Subcategory"]

<hr>

<ul>

<form method=post action=subcategory-add>
[export_form_vars category_id category_name prev_sort_key next_sort_key]
Name: <input type=text name=subcategory_name size=30>
<input type=submit value=\"Add\">
</form>

</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_html
