# /www/download/admin/download-edit-version-2.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  target page to edit downloadable file version information
#
# $Id: download-edit-version-2.tcl,v 1.1.2.2 2000/04/28 15:09:56 carsten Exp $

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# version_id release_date, pseudo_filename, version, status, visibility

ad_scope_error_check

set db [ns_db gethandle]
download_version_admin_authorize $db $version_id

# we were directed to return an error for pseudo_filename

set selection [ns_db 0or1row $db "
select download_id, creation_date, creation_user, creation_ip_address
from download_versions
where version_id=$version_id"]

set exception_count 0
set exception_text ""

if { [empty_string_p $selection] } {
    incr exception_count
    append exception_text "<li>There is no file with the given version id."
} else {
    set_variables_after_query
}

if {![info exists pseudo_filename] || [empty_string_p $pseudo_filename]} {
    incr exception_count
    append exception_text "<li>You did not enter a value for pseudo filename.<br>"
} 


set form [ns_getform]

set result_list [download_date_form_check $form release_date]
set release_date [lindex $result_list 0]
set exception_count [expr $exception_count + [lindex $result_list 1]]
append exception_text [lindex $result_list 2]

if {$exception_count > 0} {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

set selection [ns_db 1row $db "
select download_name, directory_name, description  
from downloads 
where download_id = $download_id"]

set_variables_after_query

ns_db dml $db "begin transaction"

ns_db dml $db "update download_versions
set pseudo_filename='$QQpseudo_filename',
    version ='$QQversion',
    release_date = '$release_date',
    version_description = '$QQversion_description',
    version_html_p = '$version_html_p',
    status = '$QQstatus' 
where version_id = $version_id"

ns_db dml $db "update download_rules
set visibility='$QQvisibility'
where version_id=$version_id
"

ns_db dml $db "end transaction"

set notes_string " 
File : [ad_parameter DownloadRoot download]$directory_name/$version_id.notes \n
Download ID : $download_id \n
Version ID : $version_id \n
Download Name : $download_name\n
Directory Name: $directory_name \n
Download Description : $description \n
Version Descrption : $version_description \n
Pseudo Filename : $pseudo_filename \n
Version : $version \n
Status : $QQstatus \n
Release Date : $release_date \n
Creation date: $creation_date \n
Creation User ID : $creation_user \n
Cretion IP Address : $creation_ip_address \n
"
if { $scope == "public" } {
    set stream [open [ad_parameter DownloadRoot download]$directory_name/$version_id.notes w 0777] 
} else {
    set stream [open [ad_parameter DownloadRoot download]groups/$group_id/$directory_name/$version_id.notes w 0777]    
}

puts $stream $notes_string
flush $stream
close $stream

ad_returnredirect view-one-version.tcl?[export_url_scope_vars version_id]

