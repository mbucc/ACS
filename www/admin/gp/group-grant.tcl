ad_page_contract {
    Grants a permission on a row to a user, or all users.

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id group-grant.tcl,v 3.3.2.4 2000/07/21 03:57:24 ron Exp
} {
    permission_type:notnull
    row_id:notnull,integer
    table_name:notnull
    group_id:notnull,integer
    role:optional
}

set bind_vars [ad_tcl_vars_to_ns_set permission_type row_id table_name group_id role]

if { $role == "" } {
   set permission_id [db_string perm_id_select "
        select ad_general_permissions.group_permission_id(:group_id,:permission_type,:row_id,:table_name) from dual" -default "" -bind $bind_vars]
   if { [string compare $permission_id 0] == 0 } {
       db_exec_plsql group_per_grant "begin :1 := ad_general_permissions.grant_permission_to_group($group_id, '$permission_type', $row_id, '$table_name'); end;"
   }
} else {
   set permission_id [db_string perm_id_select "
        select ad_general_permissions.group_role_permission_id(:group_id,:role,:permission_type,:row_id,:table_name) from dual" -default "" -bind $bind_vars]
    if { [string compare $permission_id 0] == 0 } {
      db_exec_plsql role_permission_grant "begin :1 := ad_general_permissions.grant_permission_to_role($group_id, '$role', '$permission_type',$row_id, '$table_name'); end;"
    }
}

ad_returnredirect "one-group.tcl?[export_url_vars group_id table_name row_id]"

