# /www/download/admin/log-entry-remove.tcl
ad_page_contract {
    removes this log entry

    @param log_id the log entry to remove
    @param return_url where to go when done
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id log-entry-remove.tcl,v 3.6.6.5 2000/09/24 22:37:16 kevin Exp
} {
    scope:optional
    group_id:optional,integer
    log_id:integer,notnull
    return_url:trim
}
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# -----------------------------------------------------------------------------

ad_scope_error_check


ad_scope_authorize $scope admin group_admin none

db_dml log_delete "delete from download_log where log_id=:log_id" 

ad_returnredirect  $return_url