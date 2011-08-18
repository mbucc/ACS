# $Id: field-delete.tcl,v 3.0 2000/02/06 03:28:38 ron Exp $
set_the_usual_form_variables
# group_type, column_name, pretty_name

set db [ns_db gethandle]

ns_return 200 text/html "[ad_admin_header "Delete Field From User Group Type"]

<h2>Delete Column $column_name</h2>

from the <a href=\"group-type.tcl?[export_url_vars group_type]\">$pretty_name</a> group type

<hr> 

<form action=\"field-delete-2.tcl\" method=POST>
[export_form_vars group_type column_name]

Do you really want to remove this field from this group type, and all 
[database_to_tcl_string $db "select count(*) from user_groups where group_type = '$QQgroup_type'"] groups of this type?
<p>
You may not be able to undo this action.
<center>
<input type=submit value=\"Yes, Remove This Field\">
</center>

[ad_admin_footer]
"