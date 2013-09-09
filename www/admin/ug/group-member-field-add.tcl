ad_page_contract {
    @param group_id the ID of the group

    @cvs-id group-member-field-add.tcl,v 3.1.6.5 2000/09/22 01:36:13 kevin Exp
} {
    group_id:notnull,naturalnum
}


set group_name [db_string group_name_get "select group_name
from user_groups
where group_id = :group_id"]

set page_html "[ad_admin_header "Add a member field to $group_name"]

<h2>Add a member field</h2>

to the <a href=\"group-type?[export_url_vars group_type]\">$group_name</a> group

<hr>

<form action=\"group-member-field-add-2\" method=POST>
[export_form_vars group_id after]

Field Name:  <input name=field_name type=text size=40>

<p>

Column Type:  [ad_user_group_column_type_widget]

<p>

<input type=submit value=\"Add this new column\">

</form>

[ad_admin_footer]
"

doc_return  200 text/html $page_html
