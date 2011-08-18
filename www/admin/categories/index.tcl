# $Id: index.tcl,v 3.1.2.1 2000/04/28 15:08:28 carsten Exp $
#
# /admin/categories/index.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# home page for category administration
#

set db [ns_db gethandle]

# If the category_hierarchy table only contains rows with null parent_category_ids, then
# we know that there are only top-level categories and that the site is not organizing
# categories hierarchically.

set n_hierarchy_links [database_to_tcl_string $db "select count(*)
from category_hierarchy
where parent_category_id is not null"]

set n_category_types [database_to_tcl_string $db "select count(distinct category_type) from categories where category_type is not null"]

# If there is a category hierarchy but there are no category types defined, then redirect to
# the tree view page.

if { $n_hierarchy_links > 0 && $n_category_types == 0 } {
    ad_returnredirect "tree.tcl"
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

    set selection [ns_db select $db "select nvl(c.category_type, 'none') as category_type, count(c.category_id) as n_categories
from categories c
group by c.category_type
order by c.category_type asc"]

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append return_html "<li>$category_type (number of categories defined: <a href=\"one-type.tcl?[export_url_vars category_type]\">$n_categories</a>)\n"
    }

} else {
    append return_html "<ul>\n"

    set selection [ns_db select $db "select category_id, category from categories order by category"]
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append return_html "<li><a href=\"one.tcl?[export_url_vars category_id]\">$category</a>\n"
    }
}

    append return_html "
<p>
<li><a href=\"category-add.tcl\">Add a category</a>
</ul>

(To define a new category type, simply add a category but instead of
picking an existing category type, enter a new one.)

"

# If a category hierarchy exists, then provide a link to the tree view page.

if { $n_hierarchy_links > 0 } {
    append return_html "<p>

You may also be interested in a tree representation of the <a
href=\"tree.tcl\">category hierarchy</a>.

"
}

append return_html "[ad_admin_footer]\n"

ns_db releasehandle $db

ReturnHeaders 

ns_write $return_html
