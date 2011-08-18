# $Id: one.tcl,v 3.1 2000/03/09 22:14:56 seb Exp $
#
# /admin/categories/one.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# displays the properties of one category
#

set_form_variables

# category_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select c.category, c.category_type, c.enabled_p, c.category_description, c.mailing_list_info, c.profiling_weight, count(ui.user_id) as n_interested_users
from users_interests ui, categories c
where ui.category_id (+) = c.category_id
and c.category_id = $category_id
group by c.category, c.category_type, c.enabled_p, c.category_description, c.mailing_list_info, c.profiling_weight"]

set_variables_after_query

#  Save this ns_set so we can use it later
set oldselection $selection

set interested_users_html $n_interested_users

if {$n_interested_users > 0} {
    set interested_users_html "<a href=\"/admin/users/action-choose.tcl?[export_url_vars category_id]\">$n_interested_users</a>"
}

set category_type_select_html [db_html_select_options $db \
    "SELECT DISTINCT category_type FROM categories ORDER BY 1" $category_type]

set parentage_lines [ad_category_parentage_list $db $category_id]

set parentage_html ""

if { [llength $parentage_lines] == 0 } {
    append parentage_html "<li>none\n"

} else {
    # Print out a Yahoo-style context bar for each line of parentage.
    #
    foreach parentage_line $parentage_lines {
	set parentage_line_html [list]
	set n_generations [llength $parentage_line]
	set this_generation [expr $n_generations - 1]
	for { set i 0 } { $i < $n_generations } { incr i } {
	    set ancestor [lindex $parentage_line $i]
	    set ancestor_category_id [lindex $ancestor 0]
	    set ancestor_category [lindex $ancestor 1]
	    if { $i != $this_generation } {
		lappend parentage_line_html \
			"<a href=\"one.tcl?category_id=$ancestor_category_id\">$ancestor_category</a>"
	    } else {
		lappend parentage_line_html $ancestor_category
	    }
	}
	append parentage_html "<li>[join $parentage_line_html " : "]\n"
    }
}


#  Now find subtree that category is root of.  We START WITH our category
#  and let Oracle find its children, grandchildren, etc.

set selection [ns_db select $db \
"SELECT c.category_id AS child_id, c.category AS child_category, hc.level_col
FROM categories c,
    (SELECT h.child_category_id, LEVEL AS level_col, ROWNUM AS row_col
    FROM category_hierarchy h
    START WITH h.child_category_id = $category_id
    CONNECT BY PRIOR h.child_category_id = h.parent_category_id) hc
WHERE c.category_id = hc.child_category_id
AND c.category_id <> $category_id
ORDER BY hc.row_col"]

set children_html ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    #  make proper indentation
    regsub -all . [format %*s [expr $level_col - 1] {}] {\&nbsp; \&nbsp; } \
	indent
    append children_html "$indent <a href=\"one.tcl?category_id=$child_id\">$child_category</a> <br>\n"
}

set category_nuke_html ""

if {$n_interested_users < 5} {
    set category_nuke_html "<p>
<li><a href=\"category-nuke.tcl?[export_url_vars category_id]\">Nuke this category</a>"
}

ns_db releasehandle $db


ReturnHeaders

ns_write "[ad_admin_header $category]

<H2>$category</H2>

[ad_admin_context_bar [list "index.tcl" "Categories"] "One category"]

<hr>

<form action=\"category-update.tcl\" method=post>
[export_form_vars category_id]
<table>
<tr>
<th align=right>Category name</th> 
<td><input size=40 name=category [export_form_value category]></td>
</tr>
<tr>
<th align=right>Category type</th> 
<td>
<select name=category_type>
$category_type_select_html
</select>
</td>
</tr>
<tr>
<th align=right> Or enter new type<br>(ignore selection above) </th>
<td> <input size=40 name=new_category_type> </td>
</tr>
<tr>
<th align=right>Profiling weight</th> 
<td><input size=10 name=profiling_weight [export_form_value profiling_weight]></td>
</tr>
<tr>
<th align=right valign=top>Category description</th>
<td>
<textarea name=category_description rows=7 cols=70 wrap=soft>
[ns_quotehtml $category_description]
</textarea>
</td>
</tr>
<tr>
<th align=right valign=top>Mailing list information</th>
<td>
<textarea name=mailing_list_info rows=7 cols=70 wrap=soft>
[ns_quotehtml $mailing_list_info]
</textarea><br>
(use this field to enter specifics about what type of spam users will get
if they express an interest in this category)
</td>
</tr>
<tr>
<th align=right>Enabled</th><td>[bt_mergepiece  "<input type=radio name=enabled_p value=\"t\">Yes 
<input type=radio name=enabled_p value=\"f\">No" $oldselection]
</td>
</tr>
</table>
<center>
<input type=submit name=submit value=\"Update\">
</center>
</form>

<ul>
<li>Number of users who've expressed interest in this category:

    $interested_users_html

</ul>

<h3>Location of this category in the category hierarchy</h3>

<ul>
<li>Parentage of this category:

<p>

<ul>

    $parentage_html

</ul>

<p>

<li>Children (subcategories) of this category:

<p>

    $children_html

</ul>

<ul>
    <li> <a href=\"category-add.tcl?parent_category_id=$category_id\">
	Add a subcategory</a> of $category
</ul>

<h3>Advanced stuff (you should know what you're doing)</h3>

<ul>
<li><a href=\"edit-parentage.tcl?[export_url_vars category_id]\">
Edit parentage of this category</a>

    $category_nuke_html

</ul>

[ad_admin_footer]
"
