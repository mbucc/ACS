# $Id: edit-parentage.tcl,v 3.1 2000/03/09 22:14:56 seb Exp $
#
# /admin/categories/edit-parentage.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# form for adding parents to and removing parents from a category
#

set_form_variables

# category_id

set db [ns_db gethandle]

set category [database_to_tcl_string $db "SELECT c.category
FROM categories c
WHERE c.category_id = $category_id"]

set parentage_lines [ad_category_parentage_list $db $category_id]

set parentage_html ""

if { [llength $parentage_lines] == 0 } {
    append parentage_html "<li>none\n"

} else {
    foreach parentage_line $parentage_lines {
	set n_generations [llength $parentage_line]
	set n_generations_excluding_self [expr $n_generations - 1]

	set parentage_line_html [list]
	for { set i 0 } { $i < $n_generations_excluding_self } { incr i } {
	    set ancestor [lindex $parentage_line $i]
	    set ancestor_category_id [lindex $ancestor 0]
	    set ancestor_category [lindex $ancestor 1]
	    lappend parentage_line_html \
		    "<a href=\"one.tcl?category_id=$ancestor_category_id\">$ancestor_category</a>"
	}

	if { [llength $parentage_line_html] == 0 } {
	    append parentage_html "<li>none\n"
	} else {
	    set parent_category_id [lindex [lindex $parentage_line [expr $n_generations - 2]] 0]

	    append parentage_html "<li>[join $parentage_line_html " : "] (<a href=\"remove-link-to-parent.tcl?[export_url_vars category_id parent_category_id]\">remove link to this parentage line</a>)\n"
	}
    }
}

ns_db releasehandle $db

ReturnHeaders

ns_write "[ad_admin_header "Edit parentage"]

<h2>Edit parentage for $category</h2>

<p>

[ad_admin_context_bar [list "index.tcl" "Categories"] [list "one.tcl?[export_url_vars category_id]" $category] "Edit parentage"]

<hr>

Lines of parentage:

<ul>

$parentage_html

<p>
<li> <a href=\"add-link-to-parent.tcl?[export_url_vars category_id]\">
Define a parent</a>
</ul>

[ad_admin_footer]
"
