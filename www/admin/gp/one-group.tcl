ad_page_contract {
    Allows editing of the permissions held by a user group on a single db row    

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id one-group.tcl,v 3.4.2.4 2000/09/22 01:35:27 kevin Exp
} {
    table_name:notnull
    row_id:notnull
    group_id:notnull
}

set bind_vars [ad_tcl_vars_to_ns_set group_id]

set group_name [db_string group_name_select "
    select
        group_name
    from
        user_groups
    where
        group_id = :group_id
" -bind $bind_vars]

set html "[ad_admin_header  "Edit Group Permissions on $table_name" ]

<h2>General Permissions Administration for $table_name</h2>
[ad_admin_context_bar  [list "index.tcl" "General Permissions"] [list "one-row.tcl?[export_url_vars table_name row_id]" "One Row"] "One Group"]
<hr>
<a href=\"one-row?[export_url_vars table_name row_id]\">back</a>
<p>
"

# we can recyle the ns_set because it already has group_id
set table_name [string toupper $table_name]
set bind_vars [ad_tcl_vars_to_ns_set -set_id $bind_vars row_id table_name]

# get the group's existing permissions
append html "<h3>Existing Record Permissions</h3>
(click to remove)
<table>
<tr><th>Role</th><th>Permission</th></tr>"
set n_permissions 0

db_foreach permission_data_select "
    select
        permission_id,
        permission_type,
        role
    from
        general_permissions
    where
        on_what_id = :row_id and
        upper(on_which_table) = :table_name and
        group_id = :group_id
    order by
        role,
        permission_type" -bind $bind_vars {
    if { $n_permissions % 2 } {
        set bgcolor "#FFFFFF"
    } else {
        set bgcolor "#DDDDDD"
    }
    if { $role == "" } {
        set role "-- any --"
    }
    append html "<tr bgcolor=\"$bgcolor\"><td>$role</td><td><a href=\"group-remove?[export_url_vars permission_id group_id row_id table_name]\">$permission_type</a></td></tr>"
    incr n_permissions
}
if { $n_permissions == 0 } {
    append html "<tr><td>none</td></tr"
}
append html "</table>"

#
# get a list of legal permission types and render them as select options
#

set permission_type_list [db_list unused "
    select
        permission_type
    from
        general_permission_types
    where
        upper(table_name) = :table_name
    order by
        permission_type
" -bind $bind_vars]

set permission_options ""
foreach permission_type $permission_type_list {
    append permission_options "<option value=\"$permission_type\">$permission_type</option>"
}

#
# get a list of roles and render them as select options as well.
#

set role_list [db_list unused "
    select distinct
        role
    from
        user_group_map"]

set role_options "<option selected value=\"\">-- any --</option>"

foreach role $role_list {
    append role_options "<option value=\"$role\">$role</option>"
}

db_release_unused_handles

append html "<h3>Add Permission</h3>
<form action=\"group-grant\">
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
        
doc_return  200 text/html $html
