# $Id: subcategory-add.tcl,v 3.0 2000/02/06 03:17:06 ron Exp $
set_the_usual_form_variables
# category_id, category_name, subcategory_name, prev_sort_key, next_sort_key

# error checking: make sure that there is no subcategory in this category
# with a sort key equal to the new sort key
# (average of prev_sort_key and next_sort_key);
# otherwise warn them that their form is not up-to-date

set db [ns_db gethandle]
set n_conflicts [database_to_tcl_string $db "select count(*)
from ec_subcategories
where category_id=$category_id
and sort_key = ($prev_sort_key + $next_sort_key)/2"]

if { $n_conflicts > 0 } {
    ad_return_complaint 1 "<li>The $category_name page appears to be out-of-date;
    perhaps someone has changed the subcategories since you last reloaded the page.
    Please go back to <a href=\"category.tcl?[export_url_vars category_id category_name]\">the $category_name page</a>, push
    \"reload\" or \"refresh\" and try again."
    return
}

ReturnHeaders

ns_write "[ad_admin_header "Confirm New Subcategory"]

<h2>Confirm New Subcategory</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Categories &amp; Subcategories"] [list "category.tcl?[export_url_vars category_id category_name]" $category_name] "Confirm New Subcategory"]

<hr>

Add the following new subcategory to $category_name?

<blockquote>
<code>$subcategory_name</code>
</blockquote>
"

set subcategory_id [database_to_tcl_string $db "select ec_subcategory_id_sequence.nextval from dual"]

ns_write "<form method=post action=subcategory-add-2.tcl>
[export_form_vars category_name category_id subcategory_name subcategory_id prev_sort_key next_sort_key]
<center>
<input type=submit value=\"Yes\">
</center>
</form>

[ad_admin_footer]
"
