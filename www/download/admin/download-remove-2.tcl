# /www/download/admin/download-remove-2.tcl
ad_page_contract {
    removes a download file

    @param download_id the download to remove
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-remove-2.tcl,v 3.4.2.6 2000/10/16 09:08:51 kolja Exp
} {
    download_id:integer,notnull
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

set user_id [download_admin_authorize $download_id]

# Now check to see if the input is good as directed by the page designer

if { ![db_0or1row download_info "
select directory_name, 
       scope as file_scope, 
       group_id as gid 
from   downloads
where  download_id = :download_id"] } {

    ad_scope_return_complaint 1 "
    <li>There is no downloadable file with id=$download_id<br>"
    return
}

# -----------------------------------------------------------------------------

db_foreach versions_for_one_download "
select version_id from download_versions 
where download_id = :download_id" {

    # remove the version from both file storage and the database 
    download_version_delete $version_id
}
    
if {$file_scope == "public"} {
    set dir_full_name "[ad_parameter DownloadRoot download]$directory_name"
} else {
    # scope is group
    set dir_full_name "[ad_parameter DownloadRoot download]groups/$gid/$directory_name"
}

if [catch {ns_rmdir $dir_full_name } errmsg] {
    # directory already exists    
    ad_return_complaint 1 "
    <li>Folder $dir_full_name could not be deleted. Make sure it is empty."
    return
}

db_dml download_delete "
delete from downloads where download_id = :download_id"
db_release_unused_handles

ad_returnredirect index?[export_url_scope_vars]

