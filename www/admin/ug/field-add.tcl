ad_page_contract {
    @param group_type the type of group
    @param after optional text
    
    @cvs-id field-add.tcl,v 3.2.2.7 2000/12/16 01:51:42 cnk Exp
} {
    group_type:notnull
    after:optional 
}


set user_id [ad_verify_and_get_user_id]

db_1row get_pretty_name "select pretty_name as group_type_pretty_name
from user_group_types 
where group_type = :group_type"


set page_html "[ad_admin_header "Add a field to $group_type_pretty_name"]

<h2>Add a field</h2>

to the <a href=\"group-type?[export_url_vars group_type]\">$group_type_pretty_name</a> group type

<hr>

<form action=\"field-add-2\" method=POST>
[export_form_vars group_type group_type_pretty_name after]

Column Actual Name:  <input name=column_name type=text size=30>
<br>
<i>no spaces or special characters except underscore</i>

<p>

Column Pretty Name:  <input name=pretty_name type=text size=30>

<p>

Column Type:  [ad_user_group_column_type_widget]

<p>

Column Actual Type:  <input name=column_actual_type type=text size=30>
(used to feed Oracle, e.g., <code>char(1)</code> instead of boolean)

<p>

If you're a database wizard, you might want to add some 
extra SQL, such as \"not null\"<br>
Extra SQL: <input type=text size=30 name=column_extra>

<p>

Note that you can only truly add not null columns when the table is
empty, i.e., before anyone has entered the contest. You should also
not declare any column as \"not null\" if the column type is
\"special\" or you will not be able to use the group information
editing pages to enter group type data.

<p>

<input type=submit value=\"Add this new column\">

</form>

[ad_admin_footer]
"

doc_return  200 text/html $page_html

