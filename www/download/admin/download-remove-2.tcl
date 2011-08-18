# /www/download/admin/download-remove-1.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  removes a download
#
# $Id: download-remove-2.tcl,v 1.1.2.2 2000/04/28 15:09:57 carsten Exp $

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# download_id

ad_scope_error_check

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db2 [lindex $db_pools 1]

ad_scope_authorize $db $scope admin group_admin none

set user_id [download_admin_authorize $db $download_id]

# Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""

set selection [ ns_db 0or1row $db "
select directory_name, 
       scope as file_scope, 
       group_id as gid 
from   downloads
where  download_id = $download_id"]

if {[empty_string_p $selection]} {
    ad_scope_return_complaint 1 "
    <li>There is no downloadable file with id=$download_id<br>" $db
    return
}

set_variables_after_query

set selection [ns_db select $db \
	"select version_id from download_versions where download_id = $download_id"]

while { [ns_db getrow $db $selection ] } {
    set_variables_after_query
    # remove the version from both file storage and the database 
    download_version_delete $db2 $version_id
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

ns_db dml $db "delete from downloads where download_id = $download_id"
ns_db releasehandle $db

ad_returnredirect index.tcl?[export_url_scope_vars]






