# /www/admin/categories/category-nuke.tcl
ad_page_contract {

  Confirmation page for nuking a category.

  @param category_id Category ID we're about to nuke

  @author sskracic@arsdigita.com
  @author michael@yoon.org 
  @creation-date October 31, 1999
  @cvs-id category-nuke.tcl,v 3.3.2.6 2000/09/22 01:34:27 kevin Exp

} {

  category_id:naturalnum,notnull

}


if {[db_string have_children_p "select count(child_category_id) from category_hierarchy where parent_category_id = :category_id" ] > 0} {
    ad_return_error "Problem nuking category" \
	"Cannot nuke category until all of its subcategories have been nuked."
    return
}

set category [db_string category_name "select category from categories where category_id = :category_id" ]



doc_return  200 text/html "[ad_admin_header "Nuke category"]

<h2>Nuke category</h2>

[ad_admin_context_bar [list index "Categories"] "Nuke category"]

<hr>

<form action=category-nuke-2 method=post>

[export_form_vars category_id]

<center>

Are you sure that you want to nuke the category \"$category\"? This action cannot be undone.

<p>

<input type=submit value=\"Yes, nuke this category now\">

</form>

[ad_admin_footer]
"
