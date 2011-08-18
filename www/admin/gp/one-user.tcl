#
# one-user.tcl
# mark@ciccarello.com
#
# allows editing of the permissions held by a single user on a single db row
# or of the permissions held by all users, or all registered users
#

set_the_usual_form_variables

#
# expects: table_name, row_id, and either
# user_id_from_search (for a single user) or scope (for all users or all registered users)
#

set db [ns_db gethandle]

if {![info exists scope]} {
    set scope ""
}


if { [info exists user_id_from_search] } {
    set selection [ns_db 1row $db "
        select
            user_id,
            first_names || ' ' || last_name as user_name
        from
            users
        where
            user_id = $user_id_from_search
    "]
    set_variables_after_query
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

if { $user_id != 0 } {
    set user_or_scope_clause "user_id = $user_id"
} else {
    set user_or_scope_clause "scope = '$scope'"
}

set selection [ns_db select $db "
    select
        permission_id,
        permission_type
    from
        general_permissions
    where
        on_what_id = '$row_id' and
        lower(on_which_table) = '[string tolower $table_name]' and
        $user_or_scope_clause
    order by
        permission_type
"]

append html "<h3>Existing Record Permissions</h3>
(click to remove)
<ul>"
set granted_permission_types ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append html "<li><a href=\"remove.tcl?[export_url_vars permission_id user_id row_id scope table_name]\">$permission_type</a></li>"
    lappend granted_permission_types $permission_type
}
if { $granted_permission_types == "" } {
    append html "<li>none</li>"
}
append html "</ul>"

append html "<h3>Available Permissions</h3>
(click to grant)
<ul>"

set selection [ns_db select $db "
    select
        permission_type
    from
        general_permission_types
    where
        lower(table_name) = '[string tolower $table_name]'
"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set granted_p "f"
    foreach granted_permission_type $granted_permission_types {
        if { $permission_type == $granted_permission_type } {
            set granted_p "t"
	}
    }
    if { $granted_p == "f" } {
        append html "<li><a href=\"grant.tcl?[export_url_vars user_id table_name row_id permission_type scope return_url]\">$permission_type</a>"
    }
}       

append html "</ul>
[ad_admin_footer]"

ns_return 200 text/html $html        


