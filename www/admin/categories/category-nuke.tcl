# $Id: category-nuke.tcl,v 3.1 2000/03/09 22:14:56 seb Exp $
#
# /admin/categories/category-nuke.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# confirmation page for nuking a category
#

set_form_variables

# category_id

set db [ns_db gethandle]

if {[database_to_tcl_string $db "select count(child_category_id) from category_hierarchy where parent_category_id = $category_id"] > 0} {
    ad_return_error "Problem nuking category" \
	"Cannot nuke category until all of its subcategories have been nuked."
    return
}

set category [database_to_tcl_string $db "select category from categories where category_id = $category_id"]

ns_db releasehandle $db

ReturnHeaders

ns_write "[ad_admin_header "Nuke category"]

<h2>Nuke category</h2>

[ad_admin_context_bar [list index.tcl "Categories"] "Nuke category"]

<hr>

<form action=category-nuke-2.tcl method=post>

[export_form_vars category_id]

<center>

Are you sure that you want to nuke the category \"$category\"? This action cannot be undone.

<p>

<input type=submit value=\"Yes, nuke this category now\">

</form>

[ad_admin_footer]
"
