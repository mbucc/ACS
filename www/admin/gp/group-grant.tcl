#
# admin/gp/group-grant.tcl
#
# mark@ciccarello.com
# February 2000
#
# grants a permission on a row to a user, or all users

set_the_usual_form_variables

#
# expects: permission_type, row_id, table_name, group_id
#

set db [ns_db gethandle]


if { $role == "" } {
   set permission_id [database_to_tcl_string_or_null $db "
        select 
            ad_general_permissions.group_permission_id('$group_id','$permission_type','$row_id','$table_name')
        from
            dual"
   ]
   if { $permission_id == "0" } {
       ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_group('$group_id', '$permission_type', '$row_id', '$table_name'); end;"
   }
} else {
   set permission_id [database_to_tcl_string_or_null $db "
        select 
            ad_general_permissions.group_role_permission_id('$group_id','$role','$permission_type','$row_id','$table_name')
        from
            dual"
   ]
    if { $permission_id == "0" } {
       ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_role('$group_id', '$role', '$permission_type','$row_id', '$table_name'); end;"
    }
}


ad_returnredirect "one-group.tcl?[export_url_vars group_id table_name row_id]"








