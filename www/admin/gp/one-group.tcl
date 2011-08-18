#
# one-group.tcl
# mark@ciccarello.com
# February 2000
# allows editing of the permissions held by a user group on a single db row
#


ad_page_variables {
    table_name
    row_id
    group_id
}

#
# expects: table_name, row_id, group_id
#

set db [ns_db gethandle]

set group_name [database_to_tcl_string $db "
    select
        group_name
    from
        user_groups
    where
        group_id = $group_id
"]



set html "[ad_admin_header  "Edit Group Permissions on $table_name" ]

<h2>General Permissions Administration for $table_name</h2>
[ad_admin_context_bar  [list "index.tcl" "General Permissions"] [list "one-row.tcl?[export_url_vars table_name row_id]" "One Row"] "One Group"]
<hr>
<a href=\"one-row.tcl?[export_url_vars table_name row_id]\">back</a>
<p>
"

#
# get the group's existing permissions
#

set selection [ns_db select $db "
    select
        permission_id,
        permission_type,
        role
    from
        general_permissions
    where
        on_what_id = '$row_id' and
        lower(on_which_table) = '[string tolower $table_name]' and
        group_id = $group_id
    order by
        role,
        permission_type
"]

append html "<h3>Existing Record Permissions</h3>
(click to remove)
<table>
<tr><th>Role</th><th>Permission</th></tr>"
set n_permissions 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $n_permissions % 2 } {
        set bgcolor "#FFFFFF"
    } else {
        set bgcolor "#DDDDDD"
    }
    if { $role == "" } {
        set role "-- any --"
    }
    append html "<tr bgcolor=\"$bgcolor\"><td>$role</td><td><a href=\"group-remove.tcl?[export_url_vars permission_id group_id row_id table_name]\">$permission_type</a></td></tr>"
    incr n_permissions
}
if { $n_permissions == 0 } {
    append html "<tr><td>none</td></tr"
}
append html "</table>"

#
# get a list of legal permission types and render them as select options
#

set permission_type_list [database_to_tcl_list $db "
    select
        permission_type
    from
        general_permission_types
    where
        lower(table_name) = '[string tolower $table_name]'
    order by
        permission_type
"]

set permission_options ""
foreach permission_type $permission_type_list {
    append permission_options "<option value=\"$permission_type\">$permission_type</option>"
}

#
# get a list of roles and render them as select options as well.
#
#

set role_list [database_to_tcl_list $db "
    select distinct
        role
    from
        user_group_map
"]

set role_options "<option selected value=\"\">-- any --</option>"
foreach role $role_list {
    append role_options "<option value=\"$role\">$role</option>"
}


append html "<h3>Add Permission</h3>
<form action=\"group-grant.tcl\">
[export_form_vars row_id table_name group_id]
<table>
<tr><td>Role:</td>
<td><select name=role>$role_options</select></td>
</tr>
<tr>
<td>Permission:</td>
<td><select name=permission_type>$permission_options</select></td>
</tr>
</table>
<input type=submit value=\"Add Permission\">
</form>
[ad_admin_footer]"
        
ns_return 200 text/html $html
