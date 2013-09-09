ad_page_contract {
    @param file_id An array of file ids to remove.
    Removes a file.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id file-remove.tcl,v 1.3.2.3 2000/07/21 03:55:42 ron Exp
} {
    {file_id:multiple}
}

db_1row apm_get_version_id "select distinct version_id from apm_package_files where file_id in ([join $file_id ","])"
db_dml apm_delete_files "delete from apm_package_files where file_id in ([join $file_id ","])"

apm_install_package_spec $version_id

db_release_unused_handles
ad_returnredirect "version-files.tcl?version_id=$version_id"
