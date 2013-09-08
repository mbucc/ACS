# /www/admin/categories/one.tcl
ad_page_contract {

  Displays the properties of one category.

  @param category_id Which category is being worked on

  @author sskracic@arsdigita.com 
  @author michael@yoon.org 
  @creation-date October 31, 1999
  @cvs-id one.tcl,v 3.4.2.6 2000/09/22 01:34:27 kevin Exp
} {

  category_id:naturalnum,notnull

}

db_1row category_properties "
select
  c.category,
  c.category_type,
  c.enabled_p,
  c.category_description,
  c.mailing_list_info,
  c.profiling_weight,
  count(ui.user_id) as n_interested_users
from
  users_interests ui,
  categories c
where
  ui.category_id (+) = c.category_id
  and c.category_id = :category_id
group by
  c.category,
  c.category_type,
  c.enabled_p,
  c.category_description,
  c.mailing_list_info,
  c.profiling_weight" 

set page_title $category

set interested_users_html $n_interested_users

if {$n_interested_users > 0} {
    set interested_users_html "<a href=\"/admin/users/action-choose?[export_url_vars category_id]\">$n_interested_users</a>"
}

set category_type_select_html \
  [db_html_select_options -select_option $category_type \
  category_type_widget "SELECT DISTINCT category_type FROM categories ORDER BY 1"]

set parentage_lines [ad_category_parentage_list $category_id]

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
			"<a href=\"one?category_id=$ancestor_category_id\">$ancestor_category</a>"
	    } else {
		lappend parentage_line_html $ancestor_category
	    }
	}
	append parentage_html "<li>[join $parentage_line_html " : "]\n"
    }
}

#  Now find subtree that category is root of.  We START WITH our category
#  and let Oracle find its children, grandchildren, etc.

set children_html ""

db_foreach all_category_children "
SELECT c.category_id AS child_id, c.category AS child_category, hc.level_col
FROM categories c,
    (SELECT h.child_category_id, LEVEL AS level_col, ROWNUM AS row_col
    FROM category_hierarchy h
    START WITH h.parent_category_id = :category_id
    CONNECT BY PRIOR h.child_category_id = h.parent_category_id) hc
WHERE c.category_id = hc.child_category_id
ORDER BY hc.row_col" {

    #  make proper indentation
    regsub -all . [format %*s [expr $level_col - 1] {}] {\&nbsp; \&nbsp; } \
	indent
    append children_html "$indent <a href=\"one?category_id=$child_id\">$child_category</a> <br>\n"
}

set category_nuke_html ""

if {$n_interested_users < 5} {
    set category_nuke_html "<p>
<li><a href=\"category-nuke?[export_url_vars category_id]\">Nuke this category</a>"
}



doc_return  200 text/html "[ad_admin_header $page_title]

<H2>$page_title</H2>

[ad_admin_context_bar [list "index" "Categories"] "One category"]

<hr>

<form action=\"category-update\" method=post>
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
<th align=right>Enabled (as a User Interest category)</th><td>[bt_mergepiece  "<input type=radio name=enabled_p value=\"t\">Yes 
<input type=radio name=enabled_p value=\"f\">No" [ad_tcl_vars_to_ns_set enabled_p]]
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
    <li> <a href=\"category-add?parent_category_id=$category_id\">
	Add a subcategory</a> of $category
</ul>

<h3>Advanced stuff (you should know what you're doing)</h3>

<ul>
<li><a href=\"edit-parentage?[export_url_vars category_id]\">
Edit parentage of this category</a>

    $category_nuke_html

</ul>

[ad_admin_footer]
"
