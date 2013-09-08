# /general-comments/upload-attachment.tcl

ad_page_contract {
    adds (or replaces) an attachment to a comment

    @author philg@mit.edu
    @author tarik@mit.edu
    @creation-date September 7, 1999
    @cvs-id upload-attachment.tcl,v 3.5.6.2 2000/07/24 06:33:03 kevin Exp
    @param upload_file  a multipart file upload
} {
    {scope ""}
    {group_id:integer ""}
    {on_which_group ""}
    {on_what_id ""}
    comment_id
    return_url
    caption
    upload_file:notnull
    upload_file.tmpfile:tmpfile
}

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# let's first check to see if this user is authorized to attach
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set comment_owner_id [db_string comment_owner_get {
    select user_id from general_comments 
    where comment_id = :comment_id
} ]

if { $user_id != $comment_owner_id } {
    ad_return_error "Unauthorized" "Ouch.  We think that you're not authorized to attach a file to this comment.  Unless you've been playing around with the HTML, this is probably our programming bug."
    return
}

# user is authorized

set tmp_filename ${upload_file.tmpfile}

set file_extension [string tolower [file extension $upload_file]]

# remove the first . from the file extension
regsub {\.} $file_extension "" file_extension

set guessed_file_type [ns_guesstype $upload_file]

set n_bytes [file size $tmp_filename]

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^/\\]+)$} $upload_file match client_filename] {
    # couldn't find a match
    set client_filename $upload_file
}

page_validation {
    if { ![empty_string_p [ad_parameter MaxAttachmentSize "general-comments"]] && $n_bytes > [ad_parameter MaxAttachmentSize "general-comments"] } {
	error "Your file is too large.  The publisher of [ad_system_name] has chosen to limit attachments to [util_commify_number [ad_parameter MaxAttachmentSize "general-comments"]] bytes.\n"
    }

    if { $n_bytes == 0 } {
	error "Your file is zero-length. Either you attempted to upload a zero length file, a file which does not exist, or something went wrong during the transfer.\n"
    }
}

set what_aolserver_told_us ""
if { $file_extension == "jpeg" || $file_extension == "jpg" } {
    catch { set what_aolserver_told_us [ns_jpegsize $tmp_filename] }
} elseif { $file_extension == "gif" } {
    catch { set what_aolserver_told_us [ns_gifsize $tmp_filename] }
}

# the AOLserver jpegsize command has some bugs where the height comes 
# through as 1 or 2 
if { ![empty_string_p $what_aolserver_told_us] && [lindex $what_aolserver_told_us 0] > 10 && [lindex $what_aolserver_told_us 1] > 10 } {
    set original_width [lindex $what_aolserver_told_us 0]
    set original_height [lindex $what_aolserver_told_us 1]
} else {
    set original_width ""
    set original_height ""
}

db_dml file_insert {
    update general_comments 
    set attachment = empty_blob(),
        client_file_name = :client_filename,
        file_type = :guessed_file_type,
        file_extension = :file_extension,
        caption = :caption,
        original_width = :original_width,
        original_height = :original_height
    where comment_id = :comment_id
    returning attachment into :1
} -blob_files [list $tmp_filename]

db_release_unused_handles

ad_returnredirect $return_url



