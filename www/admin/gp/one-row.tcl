#
# admin/gp/one-row.tcl
# mark@ciccarello.com
# February, 2000
#


ad_page_variables {
    table_name
    row_id
}

ReturnHeaders

set db [ns_db gethandle]

set selection [ns_db 1row $db "
    select
        pretty_table_name_singular, 
        pretty_table_name_plural,
        denorm_view_name,
        lower(id_column_name) as id_column_name
    from
        general_table_metadata
    where
        upper(table_name) = '[string toupper $table_name]'
"]

set_variables_after_query

ns_write "[ad_admin_header  "General Permissions Administration for $pretty_table_name_plural" ]
<h2>General Permissions Administration for $pretty_table_name_plural</h2>
[ad_admin_context_bar [list "index.tcl" "General Permissions"] [list "one-table.tcl?[export_url_vars table_name]" $table_name] "One Row"]
<hr>
<p>
"

#
# get the list of displayable columns
#

set selection [ns_db select $db "
    select 
        column_pretty_name, 
        column_name,
        is_date_p
    from
        table_metadata_denorm_columns
    where
        upper(table_name) = '[string toupper $table_name]'
    order by
        display_ordinal
"]

set column_list ""
set column_name_list ""
while { [ns_db getrow $db $selection] } {
     set_variables_after_query
     lappend column_list [list $column_pretty_name $column_name $is_date_p]
     lappend column_name_list $column_name
}


set selection [ns_db select $db "select [join $column_name_list ","] from $denorm_view_name where $id_column_name = '$row_id'"]

append html "
<table>
<h3>Database Row</h3>
"

set n 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $n % 2 } {
        set bgcolor "#FFFFFF"
    } else {
        set bgcolor "#CCCCCC"
    }
    append html "<tr bgcolor=\"$bgcolor\">"
    foreach column $column_list {
        set column_name [lindex $column 1]
        upvar 0 $column_name column_value
        append html "<tr><td><b>[lindex $column 0]:</td><td>$column_value</td></tr>"
    }
    append html "</tr>"        
    incr n
}
append html "</table>"


#
# show existing permissions
#

set selection [ns_db select $db "
    select
        permission_id,
        scope,
        general_permissions.user_id,
        first_names || ' ' || last_name as user_name,
        general_permissions.group_id,
        group_name,
        role,
        permission_type
    from
        general_permissions,
        users,
        user_groups
    where
        general_permissions.user_id = users.user_id(+) and
        general_permissions.group_id = user_groups.group_id(+) and
        on_what_id = '$row_id' and
        lower(on_which_table) = '[string tolower $table_name]'
    order by
        scope,
        user_groups.group_name,
        user_name,
        role
"]

append html "<h3>Existing Permissions</h3><table>
<tr><th>User/Group<th>Role<th>Permission Type<th></tr>
"
set permission_count 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $user_id != "" } {
        set user_id_from_search $user_id
        set name "User: <a href=\"one-user.tcl?[export_url_vars table_name row_id user_id_from_search]\">$user_name</a>"
    } elseif { $group_id != "" } {
        set name "Group: <a href=\"one-group.tcl?[export_url_vars table_name row_id group_id]\">$group_name</a>"
        if { $role == "" } {
            set role "(any)"
	}
    } else {
        if { $scope == "all_users" } {
            set name "<a href=\"one-user.tcl?[export_url_vars table_name row_id scope]\">All Users</a>"
	} elseif { $scope == "registered_users" } {
            set name "<a href=\"one-user.tcl?[export_url_vars table_name row_id scope]\">Registered Users</a>"
	}
    }
    if { $permission_count % 2 } {
        set bgcolor "#FFFFFF"
    } else {
        set bgcolor "#DDDDDD"
    }
    append html "<tr bgcolor=\"$bgcolor\"><td>$name</td><td>$role</td><td>$permission_type</td>"
    incr permission_count
}


append html "</table>
<h3>Add a new permission</h3><ul>
<li>For a <a href=\"find-user.tcl?[export_url_vars table_name row_id]\">user</a></li>
<li>For a <a href=\"find-group.tcl?[export_url_vars table_name row_id]\">user group</a></li>"

set scope "all_users"

append html "<li>For <a href=\"one-user.tcl?[export_url_vars table_name row_id scope]\">all users</a></li>"

set scope "registered_users"

append html "<li>For <a href=\"one-user.tcl?[export_url_vars table_name row_id scope]\">registered users</a></li>
</ul>
[ad_admin_footer]"

ns_db releasehandle $db

ns_write $html













































