# /www/admin/ecommerce/cat/subcategory-add.tcl

ad_page_contract {

    Confirmation page for adding a new subcategory.

    @param category_id the ID of the category
    @param category_name the name of the category
    @param subcategory_name the name of the new subcategory
    @param prev_sort_key the previous sort key.
    @param next_sort_key the next sort key

    @cvs-id subcategory-add.tcl,v 3.1.6.6 2001/01/12 17:35:52 khy Exp
} {
    category_id:integer,notnull
    category_name:notnull
    subcategory_name:notnull
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
    ad_return_complaint 1 "<li>The $category_name page appears to be out-of-date;
    perhaps someone has changed the subcategories since you last reloaded the page.
    Please go back to <a href=\"category?[export_url_vars category_id category_name]\">the $category_name page</a>, push
    \"reload\" or \"refresh\" and try again."
    return
}


set page_html "[ad_admin_header "Confirm New Subcategory"]

<h2>Confirm New Subcategory</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index" "Categories &amp; Subcategories"] [list "category?[export_url_vars category_id category_name]" $category_name] "Confirm New Subcategory"]

<hr>

Add the following new subcategory to $category_name?

<blockquote>
<code>$subcategory_name</code>
</blockquote>
"

set subcategory_id [db_string get_subcat_id_seq "select ec_subcategory_id_sequence.nextval from dual"]

append page_html "<form method=post action=subcategory-add-2>
[export_form_vars category_name category_id subcategory_name prev_sort_key next_sort_key]
[export_form_vars -sign  subcategory_id]
<center>
<input type=submit value=\"Yes\">
</center>
</form>

[ad_admin_footer]
"


doc_return  200 text/html $page_html
