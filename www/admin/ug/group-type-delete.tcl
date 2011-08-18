# $Id: group-type-delete.tcl,v 3.0 2000/02/06 03:29:07 ron Exp $
set_the_usual_form_variables

# group_type

set db [ns_db gethandle]

set selection [ns_db 1row $db "select * from user_group_types where group_type = '$QQgroup_type'"]

set_variables_after_query

ReturnHeaders 

ns_write "[ad_admin_header "Delete $pretty_name"]

<h2>Delete $pretty_name</h2>

one of <a href=\"index.tcl\">the group types</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 

<hr>

This is not an action to be taken lightly.  You are telling the system to 

<ul>
<li>remove the $pretty_name group type
<li>remove all the groups of this type (of which there are currently [database_to_tcl_string $db "select count(*) from user_groups where group_type = '$QQgroup_type'"])
<li>remove all the user-group mappings for groups of this type (of which there are currently [database_to_tcl_string $db "select count(*) 
from user_groups ug, user_group_map ugm
where ug.group_id = ugm.group_id 
and ug.group_type = '$QQgroup_type'"])


</ul>

<p>


<center>
<form method=GET action=\"group-type-delete-2.tcl\">
[export_form_vars group_type]
<input type=submit value=\"Yes, I really want to delete this group type\">
</form>
</center>



[ad_admin_footer]
"
