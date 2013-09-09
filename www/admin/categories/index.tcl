# /www/admin/categories/index.tcl
ad_page_contract {

  Home page for category administration.

  @author michael@yoon.org
  @author sskracic@arsdigita.com
  @creation-date October 31, 1999
  @cvs-id index.tcl,v 3.4.2.4 2000/09/22 01:34:27 kevin Exp
} {

}



# If the category_hierarchy table only contains rows with null parent_category_ids, then
# we know that there are only top-level categories and that the site is not organizing
# categories hierarchically.

set n_hierarchy_links [db_string n_hierarchy_links "select count(*)
from category_hierarchy
where parent_category_id is not null"]

set n_category_types [db_string n_category_types "select count(distinct category_type) from categories where category_type is not null"]

# If there is a category hierarchy but there are no category types defined, then redirect to
# the tree view page.

if { $n_hierarchy_links > 0 && $n_category_types == 0 } {
    db_release_unused_handles
    ad_returnredirect "tree"
    return
}

set return_html "

[ad_admin_header "Content Categories"]

<h2>Content Categories</h2>

[ad_admin_context_bar "Categories"]

<hr>

"

# If there are any category_types, then display them in a list, along with the number
# of categories of each type.

if { $n_category_types > 0 } {

    append return_html "Currently, categories of the following types exist:

<ul>
"

    db_foreach existing_category_types "
select
  nvl(c.category_type, 'none') as category_type,
  count(c.category_id) as n_categories
from categories c
group by c.category_type
order by c.category_type asc" {

	append return_html "<li>$category_type (number of categories defined: <a href=\"one-type?[export_url_vars category_type]\">$n_categories</a>)\n"
    }

} else {
    append return_html "<ul>\n"

    db_foreach existing_categories "
select category_id, category from categories order by category" {
	set_variables_after_query
	append return_html "<li><a href=\"one?[export_url_vars category_id]\">$category</a>\n"
    }
}

    append return_html "
<p>
<li><a href=\"category-add\">Add a category</a>
</ul>

(To define a new category type, simply add a category but instead of
picking an existing category type, enter a new one.)

"

# If a category hierarchy exists, then provide a link to the tree view page.

if { $n_hierarchy_links > 0 } {
    append return_html "<p>

You may also be interested in a tree representation of the <a
href=\"tree\">category hierarchy</a>.

"
}

append return_html "[ad_admin_footer]\n"



doc_return  200 text/html $return_html
