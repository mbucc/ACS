#
# admin/gp/remove.tcl
#
# mark@ciccarello.com
# February 2000
#
# removes a permission from a user, or all users 

set_the_usual_form_variables

#
# expects: permission_id, row_id, table_name, user_id, scope
#

set db [ns_db gethandle]

ns_db dml $db "begin ad_general_permissions.revoke_permission('$permission_id'); end;"

if { $user_id != 0 } {
    set redirection_url "one-user.tcl?[export_url_vars user_id_from_search table_name row_id]"
} else {
    set redirection_url "one-user.tcl?[export_url_vars table_name row_id scope]"
}

ad_returnredirect $redirection_url


