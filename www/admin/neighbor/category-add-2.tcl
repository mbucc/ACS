# /www/admin/neighbor/category-add-2.tcl
ad_page_contract {
    Adds a new neighbor-to-neighbor category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id category-add-2.tcl,v 3.2.2.5 2001/01/11 19:15:17 khy Exp
    @param category_id the new category's ID
    @param user_id_from_search the primary maintainer's user ID
    @param primary_category the category's name
    @param first_names_from_search the primary maintainer's first names
    @param last_name_from_search the primary maintainer's last name
    @param email_from_search the primary maintainer's email
    @param approval_policy the category's approval policy
} {
    category_id:integer,notnull,verify
    user_id_from_search:integer,notnull
    primary_category
    first_names_from_search
    last_name_from_search
    email_from_search
    approval_policy
}

set page_content "[neighbor_header "$primary_category values"]

<h2>$primary_category values</h2>

in <a href=\"index\">[neighbor_system_name] administration</a>
<hr>

<form action=\"category-update-2\" method=post>
[export_form_vars primary_category]
"



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

if { [db_string unused "select count(category_id) from n_to_n_primary_categories where category_id = :category_id"] > 0 } {
    set statement_name "category_update"
    set sql_statement_and_bind_vars [util_prepare_update n_to_n_primary_categories category_id $category_id [ns_conn form]]
} else {
    set statement_name "category_insert"
    set form_data [ns_conn form]

    ns_set delkey $form_data "category_id:sig"

    set sql_statement_and_bind_vars [util_prepare_insert n_to_n_primary_categories $form_data]
}

set sql_statement [lindex $sql_statement_and_bind_vars 0]
set bind_vars [lindex $sql_statement_and_bind_vars 1]

if [catch { db_dml $statement_name $sql_statement -bind $bind_vars} errmsg] {
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
db_1row select_category "
  select * 
    from n_to_n_primary_categories
   where category_id = :category_id"

append page_content "
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
    append page_content [bt_mergepiece $html_form [ad_tcl_vars_to_ns_set category_id primary_category top_title top_blurb primary_maintainer_id approval_policy regional_p region_type noun_for_about decorative_photo pre_post_blurb]]
} else {
    append page_content $html_form
}

append page_content "<p>If so, what type of groupings?
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


doc_return  200 text/html $page_content