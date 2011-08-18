# $Id: category-add.tcl,v 3.0 2000/02/06 03:16:54 ron Exp $
set_the_usual_form_variables
# category_name, prev_sort_key, next_sort_key

# error checking: make sure that there is no category with a sort key
# equal to the new sort key (average of prev_sort_key and next_sort_key);
# otherwise warn them that their form is not up-to-date
set db [ns_db gethandle]
set n_conflicts [database_to_tcl_string $db "select count(*)
from ec_categories
where sort_key = ($prev_sort_key + $next_sort_key)/2"]

if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The category page appears to be out-of-date;
    perhaps someone has changed the categories since you last reloaded the page.
    Please go back to <a href=\"index.tcl\">the category page</a>, push
    \"reload\" or \"refresh\" and try again."
    return
}


ReturnHeaders

ns_write "[ad_admin_header "Confirm New Category"]

<h2>Confirm New Category</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Categories &amp; Subcategories"] "Confirm New Category"]

<hr>

Add the following new category?

<blockquote>
<code>$category_name</code>
</blockquote>
"

set category_id [database_to_tcl_string $db "select ec_category_id_sequence.nextval from dual"]

ns_write "<form method=post action=category-add-2.tcl>
[export_form_vars category_name category_id prev_sort_key next_sort_key]
<center>
<input type=submit value=\"Yes\">
</center>
</form>

[ad_admin_footer]
"
