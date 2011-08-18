# $Id: subcategory-update.tcl,v 3.0 2000/02/06 03:26:20 ron Exp $
set_form_variables 0

# either subcategory_id or category_id

set db [ns_db gethandle]

if { ![info exists subcategory_id] } {
    set action "Add a subcategory"
	# get the name of the category for the user
	# interface

	set primary_category [database_to_tcl_string $db "select
primary_category from n_to_n_primary_categories where
category_id = $category_id"]

	# generate a new subcategory_id to use
	set subcategory_id [database_to_tcl_string $db "select
n_to_n_subcategory_id_seq.nextval from dual"]
} else {
       # get the previous data
       set selection [ns_db 1row $db "select n_to_n_subcategories.*, primary_category 
from n_to_n_subcategories, n_to_n_primary_categories
where subcategory_id = $subcategory_id
and n_to_n_subcategories.category_id = n_to_n_primary_categories.category_id"] 
       set_variables_after_query
       set action "Edit $subcategory_1"

}

ReturnHeaders

ns_write "[neighbor_header "$action  to $primary_category"]

<h2>$action</h2>

[ad_admin_context_bar [list "index.tcl" "Neighbor to Neighbor"] [list "category.tcl?[export_url_vars category_id]" "One Category"] "One Subcategory"]

<hr>

<form action=\"subcategory-update-2.tcl\" method=post>
"

ns_write "
What would you like to call this subcategory?  <input type=text maxlength=100 name=subcategory_1 [export_form_value subcategory_1]>
<p>
Annotation for the top of the main subcategory page:<br>
<textarea cols=50 rows=4 name=publisher_hint>[export_var publisher_hint]</textarea>
<p>
You can use the upper right section of the 
subcategory page to put an image or other custom HTML code.  An 
<code>ALIGN=RIGHT</code> is helpful.

For example:
<blockquote>
<pre>
&lt;a href=\"http://photo.net/photo/pcd3609/burano-main-square-6.tcl\"&gt;
&lt;img align=right src=\"http://photo.net/photo/pcd3609/burano-main-square-6.1.jpg\" height=50 width=50&gt;</a>
</pre>
</blockquote>

Custom HTML code:<br>
<textarea cols=50 rows=4 name=decorative_photo>[philg_quote_double_quotes [export_var decorative_photo]]</textarea><br>
<p>

<H3>Regional</h3>
Would you like these entries to be grouped by region?"

set html_form "<input type=radio name=regional_p value=\"t\">Yes
<input type=radio name=regional_p value=\"f\">No<br>"

if { [info exists regional_p] } {
    ns_write [bt_mergepiece $html_form $selection]
} else {
    ns_write $html_form
}

ns_write "<p>If so, what type of groupings?
<select name=region_type>
[ad_generic_optionlist { "" Country "US State" "US County"} { "" country us_state us_country} [export_var region_type]]
</select>
<p>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars subcategory_id category_id]
</form>
[neighbor_footer]
"
