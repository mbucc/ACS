ad_page_contract {
    Returns general permissions data on a single row.

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id one-row.tcl,v 3.4.2.5 2000/09/22 01:35:27 kevin Exp
} {
    table_name:notnull
    row_id:notnull
}

set table_name [string toupper $table_name]

db_1row table_data_select "select pretty_table_name_singular, pretty_table_name_plural,
                           denorm_view_name, lower(id_column_name) as id_column_name
                           from general_table_metadata
                           where upper(table_name) = :table_name"

set page_content "[ad_admin_header  "General Permissions Administration for $pretty_table_name_plural" ]
<h2>General Permissions Administration for $pretty_table_name_plural</h2>
[ad_admin_context_bar [list "index.tcl" "General Permissions"] [list "one-table.tcl?[export_url_vars table_name]" $table_name] "One Row"]
<hr>
<p>
"

# get the list of displayable columns

set column_list ""
set column_name_list ""

db_foreach displayable_columns_select "select column_pretty_name, column_name, is_date_p
    from table_metadata_denorm_columns
    where upper(table_name) = :table_name
    order by display_ordinal" {
	lappend column_list [list $column_pretty_name $column_name $is_date_p]
	lappend column_name_list $column_name
}

append html "
<table>
<h3>Database Row</h3>
"

set n 0

db_foreach column_select "select [join $column_name_list ","] from $denorm_view_name where $id_column_name = :row_id" {
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

append html "<h3>Existing Permissions</h3><table>
<tr><th>User/Group<th>Role<th>Permission Type<th></tr>
"

set permission_count 0

# show existing permissions

db_foreach permission_data_select "select
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
        general_permissions.user_id = users.user_id(+) 
        and general_permissions.group_id = user_groups.group_id(+) 
        and on_what_id = :row_id 
        and upper(on_which_table) = :table_name
    order by
        scope,
        user_groups.group_name,
        user_name,
        role
" {
    if { $user_id != "" } {
        set user_id_from_search $user_id
        set name "User: <a href=\"one-user?[export_url_vars table_name row_id user_id_from_search]\">$user_name</a>"
    } elseif { $group_id != "" } {
        set name "Group: <a href=\"one-group?[export_url_vars table_name row_id group_id]\">$group_name</a>"
        if { $role == "" } {
            set role "(any)"
	}
    } else {
        if { $scope == "all_users" } {
            set name "<a href=\"one-user?[export_url_vars table_name row_id scope]\">All Users</a>"
	} elseif { $scope == "registered_users" } {
            set name "<a href=\"one-user?[export_url_vars table_name row_id scope]\">Registered Users</a>"
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

db_release_unused_handles

append html "</table>
<h3>Add a new permission</h3><ul>
<li>For a <a href=\"find-user?[export_url_vars table_name row_id]\">user</a></li>
<li>For a <a href=\"find-group?[export_url_vars table_name row_id]\">user group</a></li>"

set scope "all_users"

append html "<li>For <a href=\"one-user?[export_url_vars table_name row_id scope]\">all users</a></li>"

set scope "registered_users"

append html "<li>For <a href=\"one-user?[export_url_vars table_name row_id scope]\">registered users</a></li>
</ul>
[ad_admin_footer]"

append page_content $html

doc_return 200 "text/html" $page_content