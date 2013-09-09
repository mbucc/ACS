# group-type-member-field-add.tcl

ad_page_contract {
    @param group_type the type of group 
    @cvs-id group-type-member-field-add.tcl,v 3.1.6.8 2000/09/22 01:36:14 kevin Exp
} {
    group_type:notnull
    {after ""}
}


db_1row get_type_info_ "select pretty_name 
from user_group_types 
where group_type = :group_type"


set page_html "[ad_admin_header "Add a member field to $pretty_name"]

<h2>Add a member field</h2>

to the <a href=\"group-type?[export_url_vars group_type]\">$pretty_name</a> group type

<hr>

<form action=\"group-type-member-field-add-2\" method=POST>
[export_form_vars group_type after]

Field Name:  <input name=field_name type=text size=40>

<p>

Column Type:  [ad_user_group_column_type_widget]

<p>

<input type=submit value=\"Add this new column\">

</form>

[ad_admin_footer]
"

doc_return  200 text/html $page_html
