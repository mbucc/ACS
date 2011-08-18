# $Id: add-link-to-parent.tcl,v 3.1 2000/03/09 22:14:56 seb Exp $
#
# /admin/categories/add-link-to-parent.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# form for designating a parent for a given category
#

set_form_variables

# category_id

set db [ns_db gethandle]

set category [database_to_tcl_string $db "SELECT category FROM categories WHERE category_id='$category_id'"]


# If there is no hierarchy defined, then just display a flat list of the existing categories. If there
# is, then show a fancy tree (which, btw, should be a proc).

set n_hierarchy_links [database_to_tcl_string $db "select count(*)
from category_hierarchy
where parent_category_id is not null"]

set category_html ""

if { $n_hierarchy_links > 0 } {
    append category_html "<ul>

<li> <a href=\"add-link-to-parent-2.tcl?[export_url_vars category_id]&parent_category_id=0\">Top Level</a>
"

    #  Find all children, grand-children, etc of category in question and
    #  store them in a list.  The category MUST NOT have parent among any
    #  element in this list.

    set children_list [database_to_tcl_list $db "SELECT h.child_category_id
FROM category_hierarchy h
START WITH h.child_category_id = $category_id
CONNECT BY PRIOR h.child_category_id = h.parent_category_id"]

    set parent_list [database_to_tcl_list $db "SELECT h.parent_category_id
FROM category_hierarchy h
WHERE h.child_category_id = $category_id"]

    set exclude_list [concat $children_list $parent_list]

    set selection [ns_db select $db "SELECT c.category_id AS cat_id, c.category, hc.levelcol
FROM categories c,
(SELECT h.child_category_id, LEVEL AS levelcol, ROWNUM AS rowcol
 FROM category_hierarchy h
 START WITH h.parent_category_id IS NULL
 CONNECT BY PRIOR h.child_category_id = h.parent_category_id) hc
WHERE c.category_id = hc.child_category_id
ORDER BY hc.rowcol"]

    #  We will iterate the loop for every category.  If current category
    #  falls within $exclude_list, turn off hyperlinking to prevent
    #  circular parentships or unique constraint on category_hierarchy.

    set prevlevel 0
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	set indent {}
	if {$prevlevel < $levelcol} {
	    regsub -all . [format %*s [expr $levelcol - $prevlevel] {}] \
		    "<UL> " indent
	} elseif {$prevlevel > $levelcol} {
	    regsub -all . [format %*s [expr $levelcol - $prevlevel] {}] \
		    "</UL> " indent
	}
	set prevlevel $levelcol
	append category_html "$indent <LI> "
	if {[lsearch -exact $exclude_list $cat_id] == -1} {
	    append category_html "<a href=\"add-link-to-parent-2.tcl?[export_url_vars category_id]&parent_category_id=$cat_id\">$category</a> \n"
	} else {
	    append category_html "$category \n"
	}
    }

    # Set close_tags to the appropriate number of </ul> tags

    if { [info exists levelcol] } {
        regsub -all . [format %*s $levelcol {}] "</ul> " close_tags

        append category_html "
</ul> $close_tags
"
    }

} else {

    # There's no hierarchy, so display all categories (except for this one) as possible parents.

    append category_html "<ul>\n"

    set selection [ns_db select $db "select category_id as parent_category_id, category as parent_category
from categories
where category_id <> $category_id
order by category"]

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append category_html "<li><a href=\"add-link-to-parent-2.tcl?[export_url_vars category_id parent_category_id]\">$parent_category</a>\n"
    }

    append category_html "</ul>\n"
}

ns_db releasehandle $db


ReturnHeaders

ns_write "[ad_admin_header  "Define parent"]

<H2>Define parent for $category</H2>

[ad_admin_context_bar [list "index.tcl" "Categories"] [list "one.tcl?[export_url_vars category_id]" $category] "Define parent"]

<hr>

Click on a category to designate it as a parent of $category.

<p>

$category_html

[ad_admin_footer]
"
