# /www/admin/display/upload-logo-2.tcl

ad_page_contract {
    Purpose: Uploading logo to be displayed on pages.

    @param return_url
    @param upload_file 

    @author tarik@arsdigita.com
    @creation-date 12/27/99

    @cvs-id upload-logo-2.tcl,v 3.2.2.13 2000/07/28 20:00:59 pihman Exp
} {
    upload_file:notnull
    return_url:optional
}


ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

if { ![info exists return_url] } {
    set return_url "?[export_url_scope_vars]"
}

set tmp_filename [ns_queryget upload_file.tmpfile]
set file_extension [string tolower [file extension $upload_file]]

# remove the first . from the file extension
regsub {\.} $file_extension "" file_extension

set guessed_file_type [ns_guesstype $upload_file]
set n_bytes [file size $tmp_filename]

set exception_txt ""
set exception_count 0

if { ![empty_string_p [ad_parameter MaxLogoSize display]] && \
	$n_bytes > [ad_parameter MaxLogoSize display] } {
    append exception_text "<li>Your file is too large.  The publisher of 
    [ad_system_name] has chosen to limit attachments to 
    [util_commify_number [ad_parameter MaxLogoSize display]] bytes.\n"
    incr exception_count
}

if { $n_bytes == 0 } {
    append exception_text "<li>Your file is zero-length. Either you 
    attempted to upload a zero length file, a file which does not exist, or 
    something went wrong during the transfer.\n"
    incr exception_count
}

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

if { $exception_count > 0 } {
    ad_scope_return_complaint $exception_count $exception_text
    return
}

#set logo_already_exists_p 
# [db_0or1row display_logo_select_query 
# "select 1 from page_logos where [ad_scope_sql]"]

set logo_already_exists_p [db_string display_logo_select_query "
select count(*) from page_logos where [ad_scope_sql]" -default 0]

if [catch {
    if { $logo_already_exists_p } {
	db_dml display_update_query "
	update page_logos 
	set    logo = empty_blob(), 
               logo_file_type = :guessed_file_type, 
               logo_file_extension = :file_extension
        where  [ad_scope_sql]
        returning logo into :1" -blob_files [list $tmp_filename]
    } else {
	db_dml display_insert_query "
	insert into page_logos 
         (logo_id, 
          [ad_scope_cols_sql], 
          logo_file_type, 
          logo_file_extension, 
          logo, 
          logo_enabled_p) 
         values 
         (page_logos_id_sequence.nextval, 
          [ad_scope_vals_sql], 
          :guessed_file_type, 
          :file_extension, 
           empty_blob(), 
          't') 
          returning logo into :1" -blob_files [list $tmp_filename]
    }
	
} errmsg] {
	
    # Oracle choked on the insert or update
    if { $logo_already_exists_p } {
	set insert_or_update update
    } else {
	set insert_or_update insert
    }

    ad_scope_return_error "Error in $insert_or_update" "
    We were unable to do database $insert_or_update.  
    Here is the error that was returned by Oracle:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
}

db_release_unused_handles

ad_returnredirect $return_url
    


