# /www/download/admin/edit-status.tcl
ad_page_contract {
    changes the status of a version

    @param version_id the version to change
    @param status the new status
    @param scope the scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id edit-status.tcl,v 3.7.2.5 2000/09/24 22:37:16 kevin Exp
} {
    version_id:integer,notnull
    status
    scope:optional
    group_id:optional
}

#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# -----------------------------------------------------------------------------

ad_scope_error_check

download_version_admin_authorize $version_id

db_dml unused "
update download_versions
set status=:status
where version_id=:version_id"

ad_returnredirect "view-one-version?[export_url_scope_vars version_id]"