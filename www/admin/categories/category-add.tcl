# /www/admin/categories/category-add.tcl
ad_page_contract {

  Display forms for adding a new category.

  @param category_type   Preselects appropriate category_type in displayed form
  @param parent_category_id  Inserts appropriate mapping in category_hierarchy to designate this as a parent of newly created category

  @author sskracic@arsdigita.com 
  @author michael@yoon.org 
  @creation-date October 31, 1999
  @cvs-id category-add.tcl,v 3.5.2.6 2000/09/22 01:34:27 kevin Exp
} {

  category_type:optional
  parent_category_id:naturalnum,optional

}


if {![info exists category_type]} {
    set category_type ""
}


if {![info exists parent_category_id]} {
    set parent_category_id ""
} else {
    set parent_category [db_string parent_category_name "select category
from categories
where category_id = :parent_category_id" ]
}

set category_id [db_string next_category_id "select category_id_sequence.nextval from dual"]

set category_type_select_html [db_html_select_options \
    -select_option $category_type type_selection_widget \
    "SELECT DISTINCT category_type FROM categories ORDER BY 1"]

if {[empty_string_p $category_type_select_html]} {
    set category_type_select_html {<OPTION VALUE="">}
}

set category_parentage_html ""

if {![empty_string_p $parent_category_id]} {
    append category_parentage_html "<tr>
<th align=right>Category parentage</th>
<td>
"
    # Print out a Yahoo-style context bar for each line of parentage.
    #
    set parentage_list [ad_category_parentage_list $parent_category_id]
    if {[llength $parentage_list] > 0} {
        foreach parentage_line $parentage_list {
            set parentage_line_html [list]
            foreach ancestor $parentage_line {
                set ancestor_category_id [lindex $ancestor 0]
                set ancestor_category [lindex $ancestor 1]
                lappend parentage_line_html \
                        "<a href=\"one?category_id=$ancestor_category_id\">$ancestor_category</a>"
            }
            append category_parentage_html "[join $parentage_line_html " : "]<br>\n"
        }
    } else {
        append category_parentage_html "<a href=\"one?category_id=$parent_category_id\">$parent_category</a>"
    }

    append category_parentage_html "</td>
</tr>
"
}



doc_return  200 text/html "[ad_admin_header  "Add a category"]

<H2>Add a category</H2>

[ad_admin_context_bar [list "index" "Categories"] "Add"]

<hr>

<form action=\"category-add-2\" method=post>
[export_form_vars category_id parent_category_id return_url]

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
<td><input size=10 name=profiling_weight value=1></td>
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
<th align=right>Enabled<br>(as a User Interest category)</th><td>
<input type=radio name=enabled_p value=\"t\">Yes 
<input type=radio name=enabled_p value=\"f\" checked>No
</td>
</tr>
</table>
<center>
<input type=submit name=submit value=\"Add\">
</center>
</form>

[ad_admin_footer]
"

