# /www/download/admin/download-add-2.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  target page to add new downloadable file
#
# $Id: download-add-2.tcl,v 3.2.4.4 2000/05/18 00:05:14 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# download_name, directory_name, description, html_p, download_id, group_id, scope

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

set user_id [ad_get_user_id]
set creation_ip_address [ns_conn peeraddr]

# Now check to see if the input is good as directed by the page designer

if { ![info exists return_url] } {
    set return_url "index.tcl?[export_url_scope_vars ]"
}

set exception_count 0
set exception_text ""

# we were directed to return an error for download_name

if {![info exists download_name] || [empty_string_p $download_name]} {
    incr exception_count
    append exception_text "<li>You did not enter a value for download name.<br>"
} 

# we were directed to return an error for directory_name

if {![info exists directory_name] || [empty_string_p $directory_name]} {
    incr exception_count
    append exception_text "<li>You did not enter a value for directory name.<br>"
} 

if {[string length $description] > 4000} {
    incr exception_count
    append exception_text "<li>\"description\" is too long\n"
}

if {$exception_count > 0} {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

# -----------------------------------------------------------------------------

set double_click_p [database_to_tcl_string $db \
	"select count(*) from downloads where download_id = $download_id"]

if {$double_click_p} {
    # a double click
    ad_returnredirect index.tcl?[export_url_scope_vars]
}

if {$scope == "public"} {
    set dir_full_name "[ad_parameter DownloadRoot download]$directory_name"
} else {
    # scope is group
    set dir_full_name "[ad_parameter DownloadRoot download]groups/$group_id/$directory_name"
}

set aol_version [ns_info version]

if { $aol_version < 3.0 } {
    set mkdir_command "download_mkdir $dir_full_name"  
} else {
    set mkdir_command "file mkdir $dir_full_name"
}

if [catch {eval $mkdir_command } errmsg] {
    # mkdir command failed for some reason

    ad_return_complaint 1 "
    <li>Folder $dir_full_name could not be created because of the following error:
    <blockquote>$errmsg</blockquote>
    If this is the first download for this system, then one possibility
    is that nsadmin doesn't have write privileges for the directory,
    in which case you should check with your system administrator."

    return
}


# Insert the new item into the downloads table

ns_db dml $db "
insert into downloads
 (download_id, 
  download_name, 
  directory_name, 
  description, 
  html_p, 
  creation_date, 
  creation_user, 
  creation_ip_address, 
  [ad_scope_cols_sql]) 
values 
 ($download_id, 
  '$QQdownload_name', 
  '$QQdirectory_name', 
  '$QQdescription', 
  '$html_p', 
   sysdate, 
   $user_id, 
  '$creation_ip_address', 
   [ad_scope_vals_sql])"

ad_returnredirect index.tcl?[export_url_scope_vars]








