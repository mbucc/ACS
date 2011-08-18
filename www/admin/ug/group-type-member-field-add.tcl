# $Id: group-type-member-field-add.tcl,v 3.0 2000/02/06 03:29:13 ron Exp $
set_the_usual_form_variables

# group_type

set db [ns_db gethandle]

set selection [ns_db 1row $db "select * 
from user_group_types 
where group_type = '$QQgroup_type'"]

set_variables_after_query

ReturnHeaders 

ns_write "[ad_admin_header "Add a member field to $pretty_name"]

<h2>Add a member field</h2>

to the <a href=\"group-type.tcl?[export_url_vars group_type]\">$pretty_name</a> group type

<hr>

<form action=\"group-type-member-field-add-2.tcl\" method=POST>
[export_form_vars group_type after]

Field Name:  <input name=field_name type=text size=40>

<p>

Column Type:  [ad_user_group_column_type_widget]

<p>

<input type=submit value=\"Add this new column\">

</form>

[ad_admin_footer]
"
