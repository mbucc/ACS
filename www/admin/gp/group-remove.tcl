ad_page_contract {
    Removes a permission on a row for a user group.

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id group-remove.tcl,v 3.2.6.4 2000/07/21 03:57:24 ron Exp
} {
    permission_id:notnull,naturalnum
    row_id:notnull,naturalnum
    table_name:notnull
    group_id:notnull,naturalnum
}

set bind_vars [ad_tcl_vars_to_ns_set permission_id]

db_dml group_permission_remove "begin ad_general_permissions.revoke_permission($permission_id); end;" -bind $bind_vars

db_release_unused_handles

ad_returnredirect "one-group.tcl?[export_url_vars group_id table_name row_id]"

