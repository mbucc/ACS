# File:     /admin/spam/upload-file-2.tcl
# Date:     02/06/2000
# Contact:  hqm@ai.mit.edu
# Purpose:  
#
# Upload a message file to the spam drop zone

set_the_usual_form_variables
#  clientfile as a multipart file upload
#  path as target filename (may be blank, in which case we should use clientfile)

set db [ns_db gethandle]

set exception_count 0
set exception_text ""

# let's first check to see if this user is authorized to attach
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

if { ![info exists clientfile] || [empty_string_p $clientfile] } {
    append exception_text "<li>Please specify a file to upload\n"
    incr exception_count
} else {
    # this stuff only makes sense to do if we know the file exists
    set tmp_filename [ns_queryget clientfile.tmpfile]

    if {[empty_string_p $path]} {
	set path $clientfile
    }

    # strip off the any slashes, backslashes, semis, or sequences of more than one '.'
    set path_clean [spam_sanitize_filename $path]

    set absolute_path [spam_file_location $path_clean]

    
    set n_bytes [file size $tmp_filename]

    if { $n_bytes == 0 } {
	append exception_text "<li>Your file is zero-length. Either you attempted to upload a zero length file, a file which does not exist, or something went wrong during the transfer.\n"
	incr exception_count
    }
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# copy the tmp file to the drop zone
if {[catch {ns_cp $tmp_filename $absolute_path} errmsg]} {
    ReturnHeaders
    ns_write "error copying file using ns_cp $tmp_filename $absolute_path: $errmsg"
} else {
    ad_returnredirect "show-daily-spam.tcl"
}


