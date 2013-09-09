ad_page_contract {
    
    @param group_id the group ID
    @param user_id_from_search the user ID obtained from a search
    @param role the role of the user
    @param return_url where to send the user afterwards
    
    @cvs-id member-add-2.tcl,v 3.2.2.7 2000/09/22 01:38:08 kevin Exp
} {
    group_id:notnull,naturalnum
    user_id_from_search:notnull,naturalnum
    role:optional
    return_url:optional
}

set old_role_list [db_list get_old_role_list "select role
from user_group_map
where user_id = :user_id_from_search
and group_id = :group_id"]

set name [db_string get_full_name "select first_names || ' ' || last_name from users where user_id = :user_id_from_search"]

db_1row get_group_info "select group_name, multi_role_p from user_groups where group_id = :group_id"


if {[info exists role] && ![empty_string_p $role]} {
    set title "Add $name as $role"
} else {
    set title "Specify Role and Any Extra Fields for $name"
}



set page_html "[ad_header "$title"]

<h2>$title</h2>

in <a href=\"group?group_id=$group_id\">$group_name</a>

<hr>

<form method=get action=\"member-add-3\">
<table>
"

if { [llength $old_role_list] > 0 } {

    append page_html "
Warning: $name currently has the role: [join $old_role_list ", "], which will be replaced by this operation.<p>
"
}

if { [info exists role] && ![empty_string_p $role] } {
    append page_html "[export_form_vars role]"
} else {
    
    if { [string compare $multi_role_p "t"] == 0 } {
	set existing_roles [db_list get_group_role "select role from user_group_roles where group_id = :group_id"]
	if {[lsearch $existing_roles "administrator"] == -1 } {
	    lappend existing_roles "administrator"
	}
	if { [llength $existing_roles] > 0 } {
	    append page_html "<tr><th>Role<td><select name=existing_role>
	    [ad_generic_optionlist $existing_roles $existing_roles ""]
	    </select>
	    "
	}
	append page_html "</tr>"
    } else {
	set existing_roles [db_list get_role_from_ugm "select distinct role from user_group_map where group_id = :group_id"]
	if {[lsearch $existing_roles "administrator"] == -1 } {
	    lappend existing_roles "administrator"
	}
	if {[lsearch $existing_roles "all"] == -1 } {
	    lappend existing_roles "all"
	}
	
	append page_html "<tr><th>Existing role</th><td>
	<select name=existing_role>
	<option value=\"\">choose an existing role
	"
	if { [lsearch $existing_roles member] == -1 } {
	    append page_html "<option value=\"member\">ordinary member; no special attributes\n"
	}
	if { [llength $existing_roles] > 0 } {
	    append page_html "
	    <option>[join $existing_roles "\n<option>"]"
	}
	append page_html "</select>
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
db_foreach get_additional_fields {
    select group_id, field_name, field_type
    from all_member_fields_for_group
    where group_id = :group_id
    order by sort_key
} {
    append page_html "<tr><th>$field_name
<td>[ad_user_group_type_field_form_element "extra.$field_name" $field_type]
</tr>
"
}

append page_html "
</table>
<p>

<center>
<input type=submit value=\"Confirm\">
</center>
[export_form_vars group_id user_id_from_search return_url]
</form>

[ad_footer]
"

doc_return  200 text/html $page_html





