ad_page_contract {
    Grants a permission on a row to a user, or all users, or all registered users

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id grant.tcl,v 3.3.2.7 2000/07/25 04:00:48 kevin Exp
} {
    permission_type:notnull
    row_id:notnull,naturalnum
    table_name:notnull
    user_id:naturalnum,optional
    scope:optional
}

if { [info exists user_id] && $user_id != 0 } {
    catch {db_exec_plsql permission_grant "begin :1 := ad_general_permissions.grant_permission_to_user($user_id, '$permission_type', $row_id, '$table_name'); end;"}

    set user_id_from_search $user_id
    set redirection_url "one-user.tcl?[export_url_vars user_id_from_search table_name row_id]"

} else {

    if { [info exists scope] && $scope == "all_users" } {
	catch {db_exec_plsql all_users_grant "begin :1 := ad_general_permissions.grant_permission_to_all_users('$permission_type',$row_id, '$table_name'); end;"}

    } else {
	catch {db_exec_plsql specific_permission_grant "begin :1 := ad_general_permissions.grant_permission_to_reg_users('$permission_type',$row_id, '$table_name'); end;"}
    }

    set redirection_url "one-user.tcl?[export_url_vars table_name row_id scope]"
}

db_release_unused_handles
ad_returnredirect $redirection_url

