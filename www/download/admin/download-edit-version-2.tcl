# /www/download/admin/download-edit-version-2.tcl
ad_page_contract {
    target page to edit downloadable file version information

    @param version_id the version to edit
    @param pseudo_filename the name the users see
    @param version the name of the version
    @param version_description description of the version
    @param version_html_p is the description html?
    @param status status of the version
    @param visibility who can see the version
    @param availability who can get the version
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-edit-version-2.tcl,v 3.5.2.5 2000/09/24 22:37:14 kevin Exp
} {
    version_id:integer,notnull
    pseudo_filename:trim,notnull
    version:trim,notnull
    version_description:trim,html
    version_html_p
    status
    visibility
    availability
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check


download_version_admin_authorize $version_id

set result_list [download_date_form_check [ns_getform] release_date]
set release_date [lindex $result_list 0]

page_validation {
    if { ![db_0or1row version_info "
    select download_id, 
           creation_date, 
           creation_user, 
           creation_ip_address
    from   download_versions
    where  version_id=:version_id"] } {

	error "There is no file with the given version id."
    }

    if { [lindex $result_list 1] > 0 } {
	error [lindex $result_list 2]
    }

}

db_1row download_info "
select download_name, 
       directory_name, 
       description  
from   downloads 
where  download_id = :download_id"

db_transaction {

    db_dml version_update "
    update download_versions
    set    pseudo_filename=:pseudo_filename,
           version = :version,
           release_date = :release_date,
           version_description = :version_description,
           version_html_p = :version_html_p,
           status = :status 
    where  version_id = :version_id"

    db_dml rules_update "
    update download_rules
    set    visibility   = :visibility,
           availability = :availability
    where  version_id   = :version_id"

}

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
Status : $status \n
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

ad_returnredirect view-one-version?[export_url_scope_vars version_id]

