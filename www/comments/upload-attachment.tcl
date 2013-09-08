# www/comments/upload-attachment.tcl

ad_page_contract {
    adds (or replaces) an attachment to a comment

    @author jsc@arsdigita.com
    @creation-date September 8, 1999
    @param comment_id
    @param url_stub
    @param caption
    @param upload_file
    @cvs-id upload-attachment.tcl,v 3.1.6.2 2000/07/25 06:13:15 david Exp
} {
    {comment_id:naturalnum,notnull}
    url_stub
    caption
    upload_file
}

# stolen from the general comments version

# let's first check to see if this user is authorized to attach

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set comment_owner_id [db_string comments_get_user_id "select user_id from comments where comment_id = :comment_id" -default ""]

if { $user_id != $comment_owner_id } {
    ad_return_error "Unauthorized" "Ouch.  We think that you're not authorized to attach a file to this comment.  Unless you've been playing around with the HTML, this is probably our programming bug."
    return
}

# user is authorized

set exception_text ""
set exception_count 0

if { [empty_string_p $upload_file] } {
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

    if { ![empty_string_p [ad_parameter MaxAttachmentSize "comments"]] && $n_bytes > [ad_parameter MaxAttachmentSize "comments"] } {
	append exception_text "<li>Your file is too large.  The publisher of [ad_system_name] has chosen to limit attachments to [util_commify_number [ad_parameter MaxAttachmentSize "comments"]] bytes.\n"
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

# Unable to use bind variable and blob in the same statement. Still need to be fix.
db_dml comments_attachment_upload "update comments 
set attachment = empty_blob(),
    client_file_name = '[DoubleApos $client_filename]',
    file_type = '[DoubleApos $guessed_file_type]',
    file_extension = '[DoubleApos $file_extension]',
    caption = '[DoubleApos $caption]',
    original_width = [ns_dbquotevalue $original_width number],
    original_height = [ns_dbquotevalue $original_height number]
where comment_id = $comment_id
returning attachment into :1" -blob_files [list $tmp_filename]

db_release_unused_handles
ad_returnredirect $url_stub
