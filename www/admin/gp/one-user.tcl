ad_page_contract {
    Allows editing of the permissions held by a single user on a single db row
    or of the permissions held by all users, or all registered users.

    @param table_name
    @param row_id
    @param user_id_from_search
    @param scope

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id one-user.tcl,v 3.4.2.5 2000/09/22 01:35:28 kevin Exp
} {
    table_name:html,notnull
    row_id:naturalnum,notnull
    user_id_from_search:naturalnum,optional
    {scope:html,optional ""}
}

if { [info exists user_id_from_search] } {
    if { [catch { db_1row user_data_select "select user_id, first_names || ' ' || last_name as user_name
    from users
    where user_id = :user_id_from_search" } ] } {
	db_release_unused_handles
	ad_return_error "Input error" "User $user_id_from_search not found in the database."
	return
    }
    set menu_item "One User"
} elseif { $scope == "all_users" } {
    set user_id 0
    set user_name "all users"
    set menu_item "All Users"
} else {
    set user_id 0
    set user_name "registered users"
    set menu_item "Registered Users"
}

set html "[ad_admin_header  "Edit Permissions for $user_name on $table_name $row_id" ]
<h2>Add or Edit Permissions for $user_name on $table_name $row_id</h2>
[ad_admin_context_bar [list "index.tcl" "General Permissions"] [list "one-table.tcl?[export_url_vars table_name]" $table_name] [list "one-row.tcl?[export_url_vars table_name row_id]" "One Row"] $menu_item]
<hr>
<p>
"

#
# get the user's existing permissions
#

append html "<h3>Existing Record Permissions</h3>
(click to remove)
<ul>"

set granted_permission_types ""
set table_name [string toupper $table_name]

if { $user_id != 0 } {
    set user_or_scope_clause "user_id = :user_id"
} else {
    set user_or_scope_clause "scope = :scope"
}

db_foreach permission_data_select "
    select
        permission_id,
        permission_type
    from
        general_permissions
    where
        on_what_id = :row_id and
        upper(on_which_table) = :table_name and
        $user_or_scope_clause
    order by
        permission_type" {
    append html "<li><a href=\"remove?[export_url_vars permission_id user_id row_id scope table_name]\">$permission_type</a></li>"
    lappend granted_permission_types $permission_type
}

if { $granted_permission_types == "" } {
    append html "<li>none</li>"
}
append html "</ul>"

append html "<h3>Available Permissions</h3>
(click to grant)
<ul>"

db_foreach permission_type_select "
    select
        permission_type
    from
        general_permission_types
    where
        upper(table_name) = :table_name" {
    set granted_p "f"
    foreach granted_permission_type $granted_permission_types {
        if { $permission_type == $granted_permission_type } {
            set granted_p "t"
	}
    }
    if { $granted_p == "f" } {
        append html "<li><a href=\"grant?[export_url_vars user_id table_name row_id permission_type scope return_url]\">$permission_type</a>"
    }
}

append html "</ul>
[ad_admin_footer]"

db_release_unused_handles

doc_return  200 text/html $html        

