# $Id: group-delete.tcl,v 3.0 2000/02/06 03:28:43 ron Exp $
set_the_usual_form_variables

# group_id

set db [ns_db gethandle]

set group_name [database_to_tcl_string $db "select group_name
from user_groups 
where group_id = $group_id"]

ReturnHeaders 

ns_write "[ad_admin_header "Delete group_name"]

<h2>Delete $group_name</h2>

one of <a href=\"index.tcl\">the groups</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 

<hr>

You are telling the system to 

<ul>
<li>remove the $group_name group
<li>remove all the user-group mappings for this gruop (of which there are currently [database_to_tcl_string $db "select count(*) 
from user_groups ug, user_group_map ugm
where ug.group_id = ugm.group_id 
and ug.group_id = $group_id"])

</ul>

<p>


<center>
<form method=GET action=\"group-delete-2.tcl\">
[export_form_vars group_id]
<input type=submit value=\"Yes, I really want to delete this group\">
</form>
</center>

[ad_admin_footer]
"
