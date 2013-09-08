ad_page_contract {
    Removes a given permission from the permission record.

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id remove.tcl,v 3.3.2.4 2000/07/24 04:45:49 jwong Exp
} {
    permission_id:naturalnum,notnull
    row_id:naturalnum,notnull
    table_name:notnull
    user_id:naturalnum,optional
    scope:optional
}

db_transaction {
db_dml permissions_update_dml "begin ad_general_permissions.revoke_permission(:permission_id); end;"
} on_error {
    db_release_unused_handles
    ad_return_error "Error" "Couldn't process dml request."
}

db_release_unused_handles

if { $user_id != 0 } {
    set user_id_from_search $user_id
    set redirection_url "one-user.tcl?[export_url_vars user_id_from_search table_name row_id]"
} else {
    set redirection_url "one-user.tcl?[export_url_vars table_name row_id scope]"
}

ad_returnredirect $redirection_url

