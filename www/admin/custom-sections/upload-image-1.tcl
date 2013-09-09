# /www/admin/custom-sections/upload-image-1.tcl
ad_page_contract {
    This is the target program for the form in upload-image.tcl that uploads 
    an image for the specified section in the database

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  ahmeds@arsdigita.com
    @creation-date 12/30/99

    @param section_id
    @param content_file_id
    @param upload_file
    @param file_name

    @cvs-id upload-image-1.tcl,v 3.2.2.7 2001/01/10 17:14:20 khy Exp
} {
    section_id:integer
    content_file_id:integer,verify
    upload_file:notnull
    file_name:notnull
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

#
# Additional input checks
#
set exception_text ""
set exception_count 0

# Check if file already exists
set file_name_already_exists_p [db_string "cs_select_count" "
select count (*) 
 from content_files 
 where file_name = :file_name and section_id = :section_id"]

if { $file_name_already_exists_p } {
    append exception_text "
    <li>The file with name $file_name already exists. Please choose a different file name.\n"
    incr exception_count
}

# Check if filename consists only of alphanumeric characters
if { [regexp {^[-A-Za-z0-9.]+$} $file_name] == 0 } {
    append exception_text "
    <li> The file name can only consist of alphanumeric characters and the characters '.' and '-'.\n"
    incr exception_count
}    

# Check that file is a reasonable MIME type
set tmp_filename [ns_queryget upload_file.tmpfile]
set guessed_file_type [ns_guesstype $upload_file]
set acceptable_types [split [ad_parameter AcceptablePortraitMIMETypes user-info] ]
if { [lsearch -exact $acceptable_types $guessed_file_type] == -1 } {
    append exception_text "<li>We think your file is of type $guessed_file_type. The publisher of this site
    decided that only files with one of the types [join $acceptable_types ","] can be used as
    logos.
    <p> <font size=\"-1\">If you are the publisher and you are stumped by this message, the list of 
    acceptable file types for logos is taken from the AcceptablePortraitMIMETypes parameters in the
    user-info section of your server's .ini file</font>\n"
    incr exception_count
}

# Check that file isn't empty or bigger than allowed.
set n_bytes [file size $tmp_filename]
if { ![empty_string_p [ad_parameter MaxBinaryFileSize "custom-sections"]] 
  && $n_bytes > [ad_parameter MaxBinaryFileSize "custom-sections"] } {
    append exception_text "<li>Your file is too large.  The publisher of 
    [ad_system_name] has chosen to limit attachments to 
    [util_commify_number [ad_parameter MaxBinaryFileSize "custom-sections"]] bytes.\n"
    incr exception_count
} elseif { $n_bytes == 0 } {
    append exception_text "<li>Your file is zero-length. Either you 
    attempted to upload a zero length file, a file which does not exist, or 
    something went wrong during the transfer.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_scope_return_complaint $exception_count $exception_text
    return
}

#
# Input is ok. Insert into database
# 

set file_extension [string tolower [file extension $upload_file]]
# remove the first . from the file extension
regsub {\.} $file_extension "" file_extension

if [catch {
   
    db_dml "cs_insert_content" "
    insert into content_files
    (content_file_id,section_id,file_name,binary_data ,file_type,file_extension)
    values
    (:content_file_id,:section_id,:file_name,empty_blob(),:guessed_file_type, :file_extension)
    returning binary_data into :1" -blob_files [list $tmp_filename]
    
} errmsg] {
	
    # Oracle choked on the insert
    ad_scope_return_error "Error in insert" "We were unable to do your insert in the database.  
    Here is the error that was returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
}

db_release_unused_handles

ad_returnredirect "index.tcl?[export_url_vars section_id]"

