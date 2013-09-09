ad_page_contract {
    @cvs-id member-add-2.tcl,v 3.3.2.8 2000/09/22 01:36:16 kevin Exp

    @param group_id The ID of the group being worked on
    @param user_id_from_search The user ID from user searching
    @param role The role of the new user
    @param return_url The URL return to when finished
} {
    group_id:naturalnum,notnull
    user_id_from_search:naturalnum,notnull
    {role ""}
    {return_url ""}
}

# upgraded to 3.4 by teadams on July 9th, 2000

set old_role_list [db_list user_group_role_list "
   select 
       role
   from 
       user_group_map
   where 
       user_id = :user_id_from_search
       and group_id = :group_id
"]

set name [db_string user_name_from_id "select first_names || ' ' || last_name from users where user_id = :user_id_from_search"]

db_1row user_group_properties "select group_name, multi_role_p from user_groups where group_id = :group_id"

if {[info exists role] && ![empty_string_p $role]} {
    set title "Add $name as $role"
} else {
    set title "Specify Role and Any Extra Fields for $name"
}



set page_html "[ad_admin_header "$title"]

<h2>$title</h2>

in <a href=\"group?group_id=$group_id\">$group_name</a>

<hr>

<form method=get action=\"member-add-3\">
[export_form_vars group_id user_id_from_search return_url]
<table>
"

if { [llength $old_role_list] > 0 } {

    append page_html "
Warning: $name already has the role: [join $old_role_list ", "], which will not be replaced by this operation.<p>
"
}

if { [info exists role] && ![empty_string_p $role] } {
    append page_html "[export_form_vars role]"
} else {
    
    if { [string compare $multi_role_p "t"] == 0 } {
	set existing_roles [db_list user_group_roles "select role from user_group_roles where group_id = :group_id"]
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
	set existing_roles [db_list user_group_distinct_roles "select distinct role from user_group_map where group_id = :group_id"]
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

db_foreach user_group_member_fields "select group_id, field_name, field_type
from all_member_fields_for_group
where group_id = :group_id
order by sort_key" {
    append page_html "<tr><th>$field_name
<td>[ad_user_group_type_field_form_element $field_name $field_type]
</tr>
"
}

append page_html "
</table>
<p>

<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"
doc_return  200 text/html $page_html


