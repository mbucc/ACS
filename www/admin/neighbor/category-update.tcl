# $Id: category-update.tcl,v 3.0 2000/02/06 03:26:01 ron Exp $
set_form_variables 

# category_id

set db [ns_db gethandle]

# get the category information to fill in the form

set selection [ns_db 1row $db "select * from n_to_n_primary_categories
where category_id = $category_id"] 
set_variables_after_query

ReturnHeaders

ns_write "[neighbor_header "$primary_category values"]

<h2>$primary_category values</h2>

[ad_admin_context_bar [list "index.tcl" "Neighbor to Neighbor"] [list "category.tcl?[export_url_vars category_id]" "One Category"] "Update Category"]


<hr>

<form action=\"category-update-2.tcl\" method=post>

<h3>Category name</h3>
What would you like to call this category?  <input type=text maxlength=100 name=primary_category [export_form_value primary_category]>
<p>

<H3>User Interface</H3>
By default, the category name will be used for the user interface.
If you wish to use a different title, state it here:<br>
<input type=text maxlength=100 name=top_title [export_form_value top_title]>
<p>
Annotation for the top of the main category page:<br>
<textarea cols=50 rows=4 name=top_blurb>[export_var top_blurb]</textarea>
<p>

A singular noun for pages that have to say what users are posting
about. For example, if users will be commenting on experiences they
have had buying items, you might use \"merchant\":

<br>
<input type=text name=noun_for_about [export_form_value noun_for_about merchants]><p>
You can use the upper left corner of the category page to put an image or other custom HTML code.  For example:
<blockquote>
<pre>
&lt;a href=\"http://photo.net/photo/pcd3609/burano-main-square-6.tcl\"&gt;
&lt;img src=\"http://photo.net/photo/pcd3609/burano-main-square-6.1.jpg\" height=50 width=50&gt;</a>
</pre>
</blockquote>

Custom HTML code:<br>
<textarea cols=50 rows=4 name=decorative_photo>[philg_quote_double_quotes [export_var decorative_photo]]</textarea><br>
<p>
Annotation for users about to make a posting:<br>
<textarea cols=50 rows=4 name=pre_post_blurb>[philg_quote_double_quotes [export_var pre_post_blurb]]</textarea>
<p>
<H3>Regional</h3>
Would you like users to have the option to show postings by region?"

set html_form "<input type=radio name=regional_p value=\"t\">Yes
<input type=radio name=regional_p value=\"f\">No<br>
"

if { [info exists regional_p] } {
    ns_write [bt_mergepiece $html_form $selection]
} else {
    ns_write $html_form
}

ns_write "<p>If so, what type of groupings?
<select name=region_type>
[ad_generic_optionlist { "" Country "US State" "US County"} { "" country us_state us_country} [export_var region_type]]
</select>

<h3>Administration</H3>
What type of approval system would you like for new postings?<br>
<select name=approval_policy>
[ad_generic_optionlist { "Open posting" "Admin approves postings" "Closed - Admin only" } { open wait closed } [export_var approval_policy]] 
</select>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars category_id]
</form>
[neighbor_footer]
"
