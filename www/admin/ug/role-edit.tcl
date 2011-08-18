# $Id: role-edit.tcl,v 3.0 2000/02/06 03:29:52 ron Exp $
set_the_usual_form_variables

# group_id, user_id

set db [ns_db gethandle]

set selection [ns_db 1row  $db "select first_names || ' ' || last_name as name, role, multi_role_p, group_name, group_type 
from users, user_group_map, user_groups
where users.user_id = $user_id
and user_group_map.user_id = users.user_id
and user_groups.group_id = user_group_map.group_id
and user_groups.group_id=$group_id"]
set_variables_after_query

ReturnHeaders 

ns_write "[ad_admin_header "Edit role for $name"]

<h2>Edit role for $name</h2>

in <a href=\"group.tcl?[export_url_vars group_id]\">$group_name</a>

<hr>

<form method=get action=\"role-edit-2.tcl\">
[export_form_vars group_id user_id]
<table>
<tr>
<td>Set Role
<td>
"

if { [string compare $multi_role_p "t"] == 0 } {
    # all groups must have an adminstrator role
    set existing_roles [database_to_tcl_list $db "select role from user_group_roles where group_id = $group_id"]
    if {[lsearch $existing_roles "administrator"] == -1 } {
	lappend existing_roles "administrator"
    }
    if { [llength $existing_roles] > 0 } {
	ns_write "<select name=existing_role>
	[ad_generic_optionlist $existing_roles $existing_roles $role]
	</select>
	"
    }
    ns_write "</tr>"
} else {
    set existing_roles [database_to_tcl_list $db "select distinct role from user_group_map where group_id = $group_id"]
    if {[lsearch $existing_roles "administrator"] == -1 } {
	lappend existing_roles "administrator"
    }
    if {[lsearch $existing_roles "all"] == -1 } {
	lappend existing_roles "all"
    }

    if { [llength $existing_roles] > 0 } {
	ns_write "<select name=existing_role>
	<option value=\"\">choose an existing role
	[ad_generic_optionlist $existing_roles $existing_roles $role]
	</select>
	<tr><td colspan=2 align=center>or</tr>
	<tr>
	<td>
	Define a new role for this group:
	<td>
	<input type=text name=new_role size=30>
	</tr>
	"
    }
}


ns_write "
</table>
<p>
<center>
<input type=submit value=\"Proceed\">
</center>
</form>

[ad_admin_footer]
"
