# $Id: upload-attachment.tcl,v 3.0.4.1 2000/04/28 15:10:37 carsten Exp $
# File:     /general-comments/upload-attachment.tcl
# Date:     September 7, 1999
# Contact:  philg@mit.edu, tarik@mit.edu
# Purpose:  adds (or replaces) an attachment to a comment
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# comment_id, return_url, caption plus upload_file as a multipart file upload

set db [ns_db gethandle]

# let's first check to see if this user is authorized to attach
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set comment_owner_id [database_to_tcl_string $db "select user_id from general_comments where comment_id = $comment_id"]

if { $user_id != $comment_owner_id } {
    ad_return_error "Unauthorized" "Ouch.  We think that you're not authorized to attach a file to this comment.  Unless you've been playing around with the HTML, this is probably our programming bug."
    return
}

# user is authorized

set exception_text ""
set exception_count 0

if { ![info exists upload_file] || [empty_string_p $upload_file] } {
    append exception_text "<li>Please specify a file to upload\n"
    incr exception_count
} else {
    # this stuff only makes sense to do if we know the file exists
    set tmp_filename [ns_queryget upload_file.tmpfile]

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

    if { ![empty_string_p [ad_parameter MaxAttachmentSize "general-comments"]] && $n_bytes > [ad_parameter MaxAttachmentSize "general-comments"] } {
	append exception_text "<li>Your file is too large.  The publisher of [ad_system_name] has chosen to limit attachments to [util_commify_number [ad_parameter MaxAttachmentSize "general-comments"]] bytes.\n"
	incr exception_count
    }

    if { $n_bytes == 0 } {
	append exception_text "<li>Your file is zero-length. Either you attempted to upload a zero length file, a file which does not exist, or something went wrong during the transfer.\n"
	incr exception_count
    }
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
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

ns_ora blob_dml_file $db "update general_comments 
set attachment = empty_blob(),
    client_file_name = '[DoubleApos $client_filename]',
    file_type = '[DoubleApos $guessed_file_type]',
    file_extension = '[DoubleApos $file_extension]',
    caption = '$QQcaption',
    original_width = [ns_dbquotevalue $original_width number],
    original_height = [ns_dbquotevalue $original_height number]
where comment_id = $comment_id
returning attachment into :1" $tmp_filename

ad_returnredirect $return_url
