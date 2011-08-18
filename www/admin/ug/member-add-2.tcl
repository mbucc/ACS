# $Id: member-add-2.tcl,v 3.1 2000/02/26 09:07:22 markc Exp $
set_the_usual_form_variables

# group_id, user_id_from_search, maybe role,return_url

set db [ns_db gethandle]

set old_role_list [database_to_tcl_list $db "
   select 
       role
   from 
       user_group_map
   where 
       user_id = $user_id_from_search
       and group_id = $group_id
"]

set name [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $user_id_from_search"]
set selection [ns_db 1row $db "select group_name, multi_role_p from user_groups where group_id = $group_id"]
set_variables_after_query


if {[info exists role] && ![empty_string_p $role]} {
    set title "Add $name as $role"
} else {
    set title "Specify Role and Any Extra Fields for $name"
}

ReturnHeaders 

ns_write "[ad_admin_header "$title"]

<h2>$title</h2>

in <a href=\"group.tcl?group_id=$group_id\">$group_name</a>

<hr>

<form method=get action=\"member-add-3.tcl\">
[export_form_vars group_id user_id_from_search return_url]
<table>
"

if { [llength $old_role_list] > 0 } {

    ns_write "
Warning: $name already has the role: [join $old_role_list ", "], which will not be replaced by this operation.<p>
"
}

if { [info exists role] && ![empty_string_p $role] } {
    ns_write "[export_form_vars role]"
} else {
    
    if { [string compare $multi_role_p "t"] == 0 } {
	set existing_roles [database_to_tcl_list $db "select role from user_group_roles where group_id = $group_id"]
	if {[lsearch $existing_roles "administrator"] == -1 } {
	    lappend existing_roles "administrator"
	}
	if { [llength $existing_roles] > 0 } {
	    ns_write "<tr><th>Role<td><select name=existing_role>
	    [ad_generic_optionlist $existing_roles $existing_roles ""]
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
	
	ns_write "<tr><th>Existing role</th><td>
	<select name=existing_role>
	<option value=\"\">choose an existing role
	"
	if { [lsearch $existing_roles member] == -1 } {
	    ns_write "<option value=\"member\">ordinary member; no special attributes\n"
	}
	if { [llength $existing_roles] > 0 } {
	    ns_write "
	    <option>[join $existing_roles "\n<option>"]"
	}
	ns_write "</select>
	</tr>
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


# Additional fields

set selection [ns_db select $db "select group_id, field_name, field_type
from all_member_fields_for_group
where group_id = $group_id
order by sort_key"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<tr><th>$field_name
<td>[ad_user_group_type_field_form_element $field_name $field_type]
</tr>
"
}


ns_write "
</table>
<p>

<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"
