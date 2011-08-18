# $Id: category-add.tcl,v 3.1 2000/03/09 22:14:56 seb Exp $
#
# /admin/categories/category-add.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# form for adding a new category
#

set_the_usual_form_variables 0

# category_type (optional), parent_category_id (optional)

if {![info exists category_type]} {
    set category_type ""
}

set db [ns_db gethandle]

if {![info exists parent_category_id]} {
    set parent_category_id ""
} else {
    set parent_category [database_to_tcl_string $db "select category
from categories
where category_id = $parent_category_id"]
}

set category_id [database_to_tcl_string $db "select category_id_sequence.nextval from dual"]

set category_type_select_html [db_html_select_options $db \
    "SELECT DISTINCT category_type FROM categories ORDER BY 1" $category_type]

set category_parentage_html ""

if {![empty_string_p $parent_category_id]} {
    append category_parentage_html "<tr>
<th align=right>Category parentage</th>
<td>
"

    # Print out a Yahoo-style context bar for each line of parentage.
    #
    foreach parentage_line [ad_category_parentage_list $db $parent_category_id] {
	set parentage_line_html [list]
	foreach ancestor $parentage_line {
	    set ancestor_category_id [lindex $ancestor 0]
	    set ancestor_category [lindex $ancestor 1]
	    lappend parentage_line_html \
		    "<a href=\"one.tcl?category_id=$ancestor_category_id\">$ancestor_category</a>"
	}
	append category_parentage_html "[join $parentage_line_html " : "]<br>\n"
    }

    append category_parentage_html "</td>
</tr>
"
}

ns_db releasehandle $db

ReturnHeaders

ns_write "[ad_admin_header  "Add a category"]

<H2>Add a category</H2>

[ad_admin_context_bar [list "index.tcl" "Categories"] "Add"]

<hr>


<form action=\"category-add-2.tcl\" method=post>
[export_form_vars category_id parent_category_id]

<table>
<tr>
<th align=right>Category name</th> 
<td><input size=40 name=category></td>
</tr>
<tr>
<th align=right>Category type</th>
<td>
<select name=category_type>
    $category_type_select_html
</select>
</td></tr>
<tr>
<th align=right> Or enter new type<br>(ignore selection above) </th>
<td> <input size=40 name=new_category_type> </td>
</tr>

    $category_parentage_html

<tr>
<th align=right>Profiling weight</th>
<td><input size=10 name=profiling_weight></td>
</tr>
<tr>
<th align=right valign=top>Category description</th>
<td><textarea name=category_description rows=5 cols=50 wrap=soft></textarea></td>
</tr>
<th align=right valign=top>Mailing list information</th>
<td align=left>
<textarea name=mailing_list_info rows=5 cols=50 wrap=soft></textarea><br>
(use this field to enter specifics about what type of spam users will get
if they express an interest in this category)
</td>
</tr>
<tr>
<th align=right>Enabled</th><td>
<input type=radio name=enabled_p value=\"t\" checked>Yes 
<input type=radio name=enabled_p value=\"f\">No
</td>
</tr>
</table>
<center>
<input type=submit name=submit value=\"Add\">
</center>
</form>

[ad_admin_footer]
"

