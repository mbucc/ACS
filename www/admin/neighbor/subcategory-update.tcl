# admin/neighbor/subcategory-update.tcl
ad_page_contract {
    updates a category row
    @param subcategory_id
    @param category_id
    @creation-date 2000-07-17
    @author unknown (3.4 by tnight@arsdigita.com)
    @cvs-id subcategory-update.tcl,v 3.2.2.6 2001/01/11 19:37:30 khy Exp
} {
    {subcategory_id:optional,integer}
    {category_id:optional,integer}
}

# subcategory-update.tcl,v 3.2.2.6 2001/01/11 19:37:30 khy Exp

if { ![info exists subcategory_id] } {
    set action "Add a subcategory"
	# get the name of the category for the user
	# interface

	set primary_category [db_string unused "select
primary_category from n_to_n_primary_categories where
category_id = :category_id"]

	# generate a new subcategory_id to use
	set subcategory_id [db_string unused "select
n_to_n_subcategory_id_seq.nextval from dual"]
} else {
    # get the previous data
    set sql_query "
        select n_to_n_subcategories.*, primary_category 
          from n_to_n_subcategories, n_to_n_primary_categories
         where subcategory_id = :subcategory_id
               and n_to_n_subcategories.category_id = n_to_n_primary_categories.category_id
    "
    db_1row neighbor_old_category $sql_query
    set action "Edit $subcategory_1"
}

set doc_body "[neighbor_header "$action  to $primary_category"]

<h2>$action</h2>

[ad_admin_context_bar [list "" "Neighbor to Neighbor"] [list "category?[export_url_vars category_id]" "One Category"] "One Subcategory"]

<hr>

<form action=\"subcategory-update-2\" method=post>
"

append doc_body "
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
    append doc_body [bt_mergepiece $html_form [ad_tcl_vars_to_ns_set subcategory_id category_id subcategory_1 subcategory_2 publisher_hint regional_p region_type decorative_photo primary_category]]
} else {
    append doc_body $html_form
}

append doc_body "<p>If so, what type of groupings?
<select name=region_type>
[ad_generic_optionlist { "" Country "US State" "US County"} { "" country us_state us_country} [export_var region_type]]
</select>
<p>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars -sign subcategory_id]
[export_form_vars category_id]
</form>
[neighbor_footer]
"



doc_return  200 text/html $doc_body
