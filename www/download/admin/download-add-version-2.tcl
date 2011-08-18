# /www/download/admin/download-add-version-2.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  target page to add new downloadable file version
#
# $Id: download-add-version-2.tcl,v 3.2.4.3 2000/05/18 00:05:15 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# version_id, download_id, release_date, pseudo_filename, version,
# status, upload_file, version_description, version_html_p

ad_scope_error_check

set db [ns_db gethandle]
set user_id [download_admin_authorize $db $download_id]

set creation_ip_address [ns_conn peeraddr]

# Now check to see if the input is good as directed by the page designer

set exception_count 0
set exception_text ""

if {[string length $version_description] > 4000} {
    incr exception_count
    append exception_text "<li>\"description\" is too long\n"
}

if { ![info exists upload_file] || [empty_string_p $upload_file] } {
    append exception_text "<li>Please specify a file to upload\n"
    incr exception_count
}

# we were directed to return an error for pseudo_filename

if {![info exists pseudo_filename] || [empty_string_p $pseudo_filename]} {
    incr exception_count
    append exception_text "<li>You did not enter a value for pseudo filename.<br>"
} 

set form [ns_getform]

set result_list  [download_date_form_check $form release_date]
set release_date [lindex $result_list 0]
set exception_count [expr $exception_count + [lindex $result_list 1]]
append exception_text [lindex $result_list 2]

if {$exception_count > 0} {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

# -----------------------------------------------------------------------------

set double_click_p [database_to_tcl_string $db \
	"select count(*) from download_versions where version_id = $version_id"]

if {$double_click_p} {
    ad_returnredirect index.tcl?[export_url_scope_vars]
    return
}

# Get the filenames for copying

set selection [ns_db 1row $db "
select directory_name, 
       download_name, 
       description, 
       scope as file_scope, 
       group_id as gid  
from   downloads 
where  download_id = $download_id"]

set_variables_after_query

# check if there exists a rule for all versions of this download_id

set selection [ns_db 0or1row $db "
select visibility,
       availability
from   download_rules
where  download_id = $download_id
and    version_id is null"]

if { [empty_string_p $selection ] } {
    # no rules exists for all versions, so make the default visibility to be registered users
    set visibility    "registered_users"
    set availability  "registered_users"
} else {
    set_variables_after_query
}
    
if {$file_scope == "public"} {
    set full_filename  "[ad_parameter DownloadRoot download]$directory_name/$version_id.file"
    set notes_filename "[ad_parameter DownloadRoot download]$directory_name/$version_id.notes"
} else {
    # scope is group
    set full_filename  "[ad_parameter DownloadRoot download]groups/$gid/$directory_name/$version_id.file"
    set notes_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory_name/$version_id.notes"
}

set tmp_filename [ns_queryget upload_file.tmpfile]

if [catch {ns_cp -preserve $tmp_filename $full_filename} errmsg ] {
    # file could not be copied	
    ad_scope_return_complaint 1 "
    <li>File could not be copied to $full_filename becase of the following error:
    <blockquote>$errmsg</blockquote>
    " $db
    return
} else {

    ns_db dml $db "begin transaction"
    
    ns_db dml $db "
    update download_versions
    set    status  = 'removed'
    where  version = '$version' 
    and    download_id = $download_id"
    
    ns_db dml $db "
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
     ($version_id, 
      $download_id, 
     '$release_date', 
     '$QQpseudo_filename', 
     '$QQversion', 
     '$QQversion_description', 
     '$version_html_p', 
     '$QQstatus',  
      sysdate, 
      $user_id, 
     '$creation_ip_address')"

    set new_rule_id [database_to_tcl_string $db \
	    "select download_rule_id_sequence.nextval from dual"]
    
    ns_db dml $db "
    insert into download_rules
    (rule_id, version_id, download_id, visibility, availability) 
    values 
    ($new_rule_id, '$version_id', $download_id, '$visibility', '$availability')"

    ns_db dml $db "end transaction"
    
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
    Status: $QQstatus
    Release Date: $release_date
    Creation Date: [database_to_tcl_string $db "select sysdate from dual"]
    Creation User id: $user_id
    Creation IP Address: $creation_ip_address
    "

    close $stream
}

ad_returnredirect index.tcl?[export_url_scope_vars]

