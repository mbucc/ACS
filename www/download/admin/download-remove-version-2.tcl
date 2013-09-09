# /www/download/admin/download-remove-version-2.tcl
ad_page_contract {
    removes version file

    @param version_id the version to remove
    @param scope
    @param group_id
 
    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-remove-version-2.tcl,v 3.3.2.5 2000/09/24 22:37:15 kevin Exp
} {
    version_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check


if { ![db_0or1row download_id_for_version "
select download_id
from   download_versions
where  version_id = :version_id "]} {

    ad_scope_return_complaint 1 "Download version does not exist"
    return
}

download_version_delete $version_id

ad_returnredirect view-versions?[export_url_scope_vars download_id]

