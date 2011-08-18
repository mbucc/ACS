# $Id: group-member-field-add.tcl,v 3.0 2000/02/06 03:28:50 ron Exp $
set_the_usual_form_variables

# group_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select group_name
from user_groups
where group_id = $group_id"]

set_variables_after_query

ReturnHeaders 

ns_write "[ad_admin_header "Add a member field to $group_name"]

<h2>Add a member field</h2>

to the <a href=\"group-type.tcl?[export_url_vars group_type]\">$group_name</a> group

<hr>

<form action=\"group-member-field-add-2.tcl\" method=POST>
[export_form_vars group_id after]

Field Name:  <input name=field_name type=text size=40>

<p>

Column Type:  [ad_user_group_column_type_widget]

<p>

<input type=submit value=\"Add this new column\">

</form>

[ad_admin_footer]
"
