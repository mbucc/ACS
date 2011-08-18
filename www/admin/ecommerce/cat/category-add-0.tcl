# $Id: category-add-0.tcl,v 3.0 2000/02/06 03:16:52 ron Exp $
set_the_usual_form_variables
# prev_sort_key, next_sort_key

# error checking: make sure that there is no category with a sort key
# equal to the new sort key (average of prev_sort_key and next_sort_key);
# otherwise warn them that their form is not up-to-date
set db [ns_db gethandle]
set n_conflicts [database_to_tcl_string $db "select count(*)
from ec_categories
where sort_key = ($prev_sort_key + $next_sort_key)/2"]

if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The page you came from appears to be out-of-date;
    perhaps someone has changed the categories since you last reloaded the page.
    Please go back to the previous page, push \"reload\" or \"refresh\" and try
    again."
    return
}


ReturnHeaders

ns_write "[ad_admin_header "Add a New Category"]

<h2>Add a New Category</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Categories"] "Add a New Category"]

<hr>

<ul>

<form method=post action=category-add.tcl>
[export_form_vars prev_sort_key next_sort_key]
Name: <input type=text name=category_name size=30>
<input type=submit value=\"Add\">
</form>

</ul>

[ad_admin_footer]
"