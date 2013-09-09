# /www/download/admin/download-add-version-2.tcl
ad_page_contract {
    Uploads and inserts a new version

    @param scope
    @param group_id
    @param user_id
    @param version_id the ID for the new version
    @param download_id the ID for the file
    @param pseudo_filename the filename the user sees
    @param version the version name
    @param status current status of the file
    @param upload_file the file being uploaded (the new version)
    @param version_description description of the new version

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-add-version-2.tcl,v 3.10.2.6 2000/09/24 22:37:14 kevin Exp
} {
    scope:optional
    {group_id:integer ""}
    {user_id:integer ""}
    version_id:integer,notnull
    download_id:integer,notnull
    pseudo_filename:trim,notnull
    version:trim
    status
    upload_file
    upload_file.tmpfile:tmpfile
    version_description:html
    version_html_p
}

# -----------------------------------------------------------------------------

ad_scope_error_check

set user_id [download_admin_authorize $download_id]

set creation_ip_address [ns_conn peeraddr]

# Now check to see if the input is good as directed by the page designer

set result_list  [download_date_form_check [ns_getform] release_date]
set release_date [lindex $result_list 0]

page_validation {

    if {[string length $version_description] > 4000} {
        error "\"description\" is too long\n"
    }

    if {[lindex $result_list 1] != 0 } {
	error [lindex $result_list 2]
    }

}

# -----------------------------------------------------------------------------

set bind_vars [ad_tcl_vars_to_ns_set version_id download_id version \
	pseudo_filename version_description version_html_p status \
	user_id creation_ip_address release_date]

set double_click_p [db_string existing_versions "
select count(*) from download_versions 
where version_id = :version_id" -bind $bind_vars]

if {$double_click_p} {
    ad_returnredirect index?[export_url_scope_vars]
    return
}

# Get the filenames for copying

db_1row download_info "
select directory_name, 
       download_name, 
       description, 
       scope as file_scope, 
       group_id as gid  
from   downloads 
where  download_id = :download_id"


# check if there exists a rule for all versions of this download_id

if { ! [db_0or1row download_rules "
select visibility,
       availability
from   download_rules
where  download_id = :download_id
and    version_id is null"] } { 

    # no rules exists for all versions, so make the default visibility to be registered users
    set visibility    "registered_users"
    set availability  "registered_users"
}
    
if {$file_scope == "public"} {
    set full_filename  "[ad_parameter DownloadRoot download]$directory_name/$version_id.file"
    set notes_filename "[ad_parameter DownloadRoot download]$directory_name/$version_id.notes"
} else {
    # scope is group
    set full_filename  "[ad_parameter DownloadRoot download]groups/$gid/$directory_name/$version_id.file"
    set notes_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory_name/$version_id.notes"
}

set tmp_filename ${upload_file.tmpfile}

if [catch {ns_cp -preserve $tmp_filename $full_filename} errmsg ] {
    # file could not be copied	
    ad_scope_return_complaint 1 "
    <li>File could not be copied to $full_filename becase of the following error:
    <blockquote>$errmsg</blockquote>"
    return
} else {

    db_transaction {
    
	db_dml version_update "
	update download_versions
	set    status  = 'removed'
	where  version = :version 
	and    download_id = :download_id"
	
	db_dml unused "
	insert into download_versions
	(version_id, 
	download_id, 
	release_date, 
	pseudo_filename, 
	version,
	version_description, 
	version_html_p, 
	status, 
	creation_date, 
	creation_user, 
	creation_ip_address) 
	values 
	(:version_id, 
	 :download_id, 
	 :release_date, 
	 :pseudo_filename, 
	 :version, 
	 :version_description, 
	 :version_html_p, 
	 :status,  
	 sysdate, 
	 :user_id, 
	 :creation_ip_address)"

	set new_rule_id [db_string next_rule_id "
	select download_rule_id_sequence.nextval from dual"]
    
	db_dml rule_insert "
	insert into download_rules
	(rule_id, version_id, download_id, visibility, availability) 
	values 
	(:new_rule_id, :version_id, :download_id, :visibility, :availability)
	"

    }
    
    # now store the detail oracle information in the .notes file for the administrator to read
    
    set   stream [open $notes_filename w]
    puts  $stream "
    File: [ad_parameter DownloadRoot download]$directory_name/$version_id.notes

    Download id: $download_id
    Version id: $version_id
    Download Name: $download_name
    Directory Name: $directory_name
    Download Description: $description
    Version Description: $version_description
    Pseudo Filename: $pseudo_filename
    Version: $version
    Status: $status
    Release Date: $release_date
    Creation Date: [db_string sysdate "select sysdate from dual"]
    Creation User id: $user_id
    Creation IP Address: $creation_ip_address
    "

    close $stream
}

ad_returnredirect index?[export_url_scope_vars]

