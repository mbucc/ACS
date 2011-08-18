# $Id: upload-logo-2.tcl,v 3.0.4.1 2000/04/28 15:08:34 carsten Exp $
# File:     /admin/css/upload-logo-2.tcl
# Date:     12/27/99
# Contact:  tarik@arsdigita.com
# Purpose:  uploading logo to be displayed on pages
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)


set_form_variables 0
# maybe return_url
# maybe scope, maybe scope related variables (group_id, user_id)

if { ![info exists return_url] } {
    set return_url "index.tcl?[export_url_scope_vars]"
}

ad_scope_error_check

set db [ns_db gethandle]

set exception_count 0
set exception_text ""

if { ![info exists upload_file] || [empty_string_p $upload_file] } {
    append exception_text "<li>Please specify a file to upload\n"
    incr exception_count
}

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


if { ![empty_string_p [ad_parameter MaxLogoSize display]] && $n_bytes > [ad_parameter MaxLogoSize display] } {
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


if { $exception_count > 0 } {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

    
set logo_already_exists_p [ad_decode [ns_db 0or1row $db "select 1 from page_logos where [ad_scope_sql]"] "" 0 1]

if [catch {
    if { $logo_already_exists_p } {
	ns_ora blob_dml_file $db "
	update page_logos
	set logo= empty_blob(),
	logo_file_type= '$guessed_file_type',
	logo_file_extension= '$file_extension'
	where [ad_scope_sql]
	returning logo into :1" $tmp_filename
	
    } else {
	ns_ora blob_dml_file $db "
	insert into page_logos
	(logo_id, [ad_scope_cols_sql], logo_file_type, logo_file_extension, logo, logo_enabled_p)
	values
	(page_logos_id_sequence.nextval, [ad_scope_vals_sql], '$guessed_file_type', '$file_extension', empty_blob(), 't')
	returning logo into :1" $tmp_filename
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
    </blockquote>" $db
    return
}

ad_returnredirect $return_url
    


