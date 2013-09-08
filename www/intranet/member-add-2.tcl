# /www/intranet/member-add-2.tcl

ad_page_contract {
    Purpose: Confirms adding of person to group

    @param user_id_from_search user_id to add
    @param group_id group to which to add
    @param role role in which to add
    @param return_url Return URL
    @param also_add_to_group_id Additional groups to which to add

    @author mbryzek@arsdigita.com
    @creation-date 4/16/2000

    @cvs-id member-add-2.tcl,v 3.5.2.8 2000/10/27 00:03:00 tony Exp
} {
    user_id_from_search:integer
    group_id:integer
    { role "" }
    { return_url "" }
    { also_add_to_group_id:integer "" }
}



set old_role_list [db_list available_roles "select role
from user_group_map
where user_id = $user_id_from_search
and group_id = :group_id"]

db_1row user_name \
	"select first_names || ' ' || last_name as name
           from users 
          where user_id = :user_id_from_search"

db_1row group_name \
	"select group_name, multi_role_p 
           from user_groups
          where group_id = :group_id" 

if {![empty_string_p $role]} {
    set page_title "Add $name as $role"
} else {
    set page_title "Specify Role and Any Extra Fields for $name"
}

set context_bar [ad_context_bar_ws "Confirm new member"]

set page_content "

<b>in $group_name</b>

<form method=get action=member-add-3>
[export_form_vars group_id user_id_from_search return_url also_add_to_group_id]
<table>
"

if { [llength $old_role_list] > 0 } {

    append page_content "
Warning: $name currently has the role: [join $old_role_list ", "], which will be replaced by this operation.<p>
"
}

if { [info exists role] && ![empty_string_p $role] } {
    append page_content "[export_form_vars role]"
} else {
    
    if { [string compare $multi_role_p "t"] == 0 } {
	set existing_roles [db_list roles_for_group \
		"select role from user_group_roles where group_id = :group_id"]
	if {[lsearch $existing_roles "administrator"] == -1 } {
	    lappend existing_roles "administrator"
	}
	if { [llength $existing_roles] > 0 } {
	    append page_content "<tr><th>Role<td><select name=existing_role>
	    [ad_generic_optionlist $existing_roles $existing_roles ""]
	    </select>
	    "
	}
	append page_content "</tr>"
    } else {
	set existing_roles [db_list distinct_roles_for_group \
		"select distinct role from user_group_map where group_id = :group_id"]
	if {[lsearch $existing_roles "administrator"] == -1 } {
	    lappend existing_roles "administrator"
	}
	if {[lsearch $existing_roles "all"] == -1 } {
	    lappend existing_roles "all"
	}
	
	append page_content "<tr><th>Existing role</th><td>
	<select name=existing_role>
	<option value=\"\">choose an existing role
	"
	if { [lsearch $existing_roles member] == -1 } {
	    append page_content "<option value=\"member\">ordinary member; no special attributes\n"
	}
	if { [llength $existing_roles] > 0 } {
	    append page_content "
	    <option>[join $existing_roles "\n<option>"]"
	}
	append page_content "</select>
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

set sql "select group_id, field_name, field_type
from all_member_fields_for_group
where group_id = :group_id
order by sort_key"

db_foreach member_field_info $sql {
    append page_content "<tr><th>$field_name
<td>[ad_user_group_type_field_form_element $field_name $field_type]
</tr>
"
}

append page_content "
</table>
<p>
"

if { $group_id == [im_employee_group_id] } {
    append page_content "Start date: [ad_dateentrywidget start_date]"
}

append page_content "
<center>
<input type=submit value=\"Confirm\">
</center>
</form>
"



doc_return  200 text/html [im_return_template]
