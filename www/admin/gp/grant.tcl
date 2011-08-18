#
# admin/gp/grant.tcl
#
# mark@ciccarello.com
# February 2000
#
# grants a permission on a row to a user, or all users, or all registered users

set_the_usual_form_variables

#
# expects: permission_type, row_id, table_name, user_id,  scope
#


set db [ns_db gethandle]

if { $user_id != 0 } {
    ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_user('$user_id', '$permission_type', '$row_id', '$table_name'); end;"
    set user_id_from_search $user_id
    set redirection_url "one-user.tcl?[export_url_vars user_id_from_search table_name row_id]"
} else {
    if { $scope == "all_users" } {
        ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_all_users('$permission_type','$row_id', '$table_name'); end;"
    } else {
        ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_reg_users('$permission_type','$row_id', '$table_name'); end;"
    }
    set redirection_url "one-user.tcl?[export_url_vars table_name row_id scope]"
}

ad_returnredirect $redirection_url







