# $Id: category-add-2.tcl,v 3.0 2000/02/06 03:25:47 ron Exp $
set_form_variables 

# category_id, user_id_from_search, category_name
# first_names_from_search, last_name_from_search, email_from_search
# approval_policy

# submit


# user error checking

set exception_text ""
set exception_count 0


if { ![info exist primary_category] || [empty_string_p $primary_category] } {
    incr exception_count
    append exception_text "<li>Please enter a category name."
}


if { $exception_count > 0 } { 
  ad_return_complaint $exception_count $exception_text
  return
}



ReturnHeaders

ns_write "[neighbor_header "$primary_category values"]

<h2>$primary_category values</h2>

in <a href=\"index.tcl\">[neighbor_system_name] administration</a>
<hr>

<form action=\"category-update-2.tcl\" method=post>
[export_form_vars primary_category]
"

set db [ns_db gethandle]

# edit the form vars so we can use the magic insert/update
ns_set delkey [ns_conn form] submit
ns_set delkey [ns_conn form] user_id_from_search
ns_set delkey [ns_conn form] last_name_from_search
ns_set delkey [ns_conn form] first_names_from_search
ns_set delkey [ns_conn form] email_from_search
ns_set update [ns_conn form] primary_maintainer_id $user_id_from_search

# Check the database to see if there is a row for this category already.
# If there is a row, update the database with the information from the form.
# If there is no row, insert into the database with the information from the form.

if { [database_to_tcl_string $db "select count(category_id) from n_to_n_primary_categories where category_id = $category_id"] > 0 } {
    set sql_statement  [util_prepare_update $db n_to_n_primary_categories category_id $category_id [ns_conn form]]
} else {
    set sql_statement  [util_prepare_insert $db n_to_n_primary_categories category_id $category_id [ns_conn form]]
}

 
if [catch { ns_db dml $db $sql_statement } errmsg] {
	    ad_return_error "Failure to update category  information" "The database rejected the attempt:
	    <blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

# there is now a row for this category
# get the category information to fill in the form

set selection [ns_db 1row $db "select * from n_to_n_primary_categories
where category_id = $category_id"] 
set_variables_after_query

ns_write "
<H3>User Interface</H3>
By default, the category name will be used for the user interface.
If you wish to use a different title, state it here:<br>
<input type=text maxlength=100 name=top_title [export_form_value top_title]>
<p>
Annotation for the top of the main category page:<br>
<textarea cols=50 rows=4 name=top_blurb>[export_var top_blurb]</textarea>
<p>
We tell users what they are posting about. For example, if users will be commenting on experiences they have had buying items, you might use \"merchants\":
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
<H3>Regional</h3>
Would you like users to have the option to show postings by region?"

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

<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars category_id]
</form>
[neighbor_footer]
"
