# $Id: index.tcl,v 3.0 2000/02/06 03:17:02 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Product Category Administration"]

<h2>Product Category Administration</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] "Product Categories"]

<hr>

<h3>Current Categories</h3>

<blockquote>
<table>
"

set db [ns_db gethandle]
set selection [ns_db select $db "select category_id, sort_key, category_name from ec_categories order by sort_key"]

set old_category_id ""
set old_sort_key ""
set category_counter 0

while { [ns_db getrow $db $selection] } {
    incr category_counter
    set_variables_after_query
    if { ![empty_string_p $old_category_id] } {
	ns_write "<td> &nbsp;&nbsp;<font face=\"MS Sans Serif, arial,helvetica\"  size=1><a href=\"category-add-0.tcl?prev_sort_key=$old_sort_key&next_sort_key=$sort_key\">insert after</a> &nbsp;&nbsp; <a href=\"category-swap.tcl?category_id=$old_category_id&next_category_id=$category_id&sort_key=$old_sort_key&next_sort_key=$sort_key\">swap with next</a></font></td></tr>"
    }
    set old_category_id $category_id
    set old_sort_key $sort_key
    ns_write "<tr><td>$category_counter. <a href=\"category.tcl?[export_url_vars category_id category_name]\">$category_name</a></td>\n"
}

if { $category_counter != 0 } {
    ns_write "<td> &nbsp;&nbsp;<font face=\"MS Sans Serif, arial,helvetica\"  size=1><a href=\"category-add-0.tcl?prev_sort_key=$old_sort_key&next_sort_key=[expr $old_sort_key + 2]\">insert after</a></font></td></tr>
    "
} else {
    ns_write "You haven't set up any categories.  <a href=\"category-add-0.tcl?prev_sort_key=1&next_sort_key=2\">Add a category.</a>\n"
}

ns_write "
</table>
</blockquote>


[ad_admin_footer]
"




