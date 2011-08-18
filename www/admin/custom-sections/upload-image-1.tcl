# $Id: upload-image-1.tcl,v 3.0.4.1 2000/04/28 15:08:33 carsten Exp $
# File:     admin/custom-sections/upload-image-1.tcl
# Date:     12/30/99
# Contact:  ahmeds@arsdigita.com
# Purpose:  This is the target program for the form in upload-image.tcl
#           that uploads an image for the specified section in the database

#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)


set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# section_id,content_file_id,  upload_file , file_name

ad_scope_error_check

set db [ns_db gethandle]

ad_scope_authorize $db $scope admin group_admin none

set exception_count 0
set exception_text ""

if { ![info exists upload_file] || [empty_string_p $upload_file] } {
    append exception_text "<li>Please specify a file to upload\n"
    incr exception_count
}
if { ![info exists file_name] || [empty_string_p $file_name] } {
    incr exception_count
    append exception_text "<li>No file name was passed. Please specify a file name of the image you want to upload."
}
if {$exception_count > 0} { 
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}


set file_name_already_exists_p [database_to_tcl_string $db "
select count(*) 
from content_files
where file_name='$QQfile_name'
and section_id = $section_id"]

if { $file_name_already_exists_p } {
    append exception_text "
    <li>The file with name $file_name already exists. Please choose a different file name.\n"
    incr exception_count
}

# conflict with system filename has to be checked later

if {$exception_count > 0} { 
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

set tmp_filename [ns_queryget upload_file.tmpfile]
    
set file_extension [string tolower [file extension $upload_file]]
    
# remove the first . from the file extension
regsub {\.} $file_extension "" file_extension
    
set guessed_file_type [ns_guesstype $upload_file]
    
set n_bytes [file size $tmp_filename]
  
    
if { ![empty_string_p [ad_parameter MaxBinaryFileSize "custom-sections"]] && 
$n_bytes > [ad_parameter MaxBinaryFileSize "custom-sections"] } {
    append exception_text "<li>Your file is too large.  The publisher of 
    [ad_system_name] has chosen to limit attachments to 
    [util_commify_number [ad_parameter MaxBinaryFileSize "custom-sections"]] bytes.\n"
    incr exception_count
}

if { $n_bytes == 0 } {
    append exception_text "<li>Your file is zero-length. Either you 
    attempted to upload a zero length file, a file which does not exist, or 
    something went wrong during the transfer.\n"
    incr exception_count
}

    
if { $exception_count > 0 } {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}


if [catch {
   
    ns_ora blob_dml_file $db "
    insert into content_files
    (content_file_id,section_id,file_name,binary_data ,file_type,file_extension)
    values
    ($content_file_id,$section_id,'$QQfile_name',empty_blob(),'$guessed_file_type', '$file_extension')
    returning binary_data into :1" $tmp_filename
    
} errmsg] {
	
    # Oracle choked on the insert
    ad_scope_return_error "Error in insert" "We were unable to do your insert in the database.  
    Here is the error that was returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>" $db
    return
}

ad_returnredirect "index.tcl?[export_url_scope_vars section_id]"










