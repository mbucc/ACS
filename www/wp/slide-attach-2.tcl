# $Id: slide-attach-2.tcl,v 3.0.4.1 2000/04/28 15:11:41 carsten Exp $
# File:        slide-attach-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Adds an attachment.
# Inputs:      slide_id, attachment (file), inline_image_p, display

set_the_usual_form_variables
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

set selection [ns_db 1row $db "select * from wp_slides where slide_id = $slide_id"]
set_variables_after_query
wp_check_authorization $db $presentation_id $user_id "write"

set tmp_filename [ns_queryget attachment.tmpfile]
set guessed_file_type [ns_guesstype $attachment]
set n_bytes [file size $tmp_filename]

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^/\\]+)$} $attachment match client_filename] {
    set client_filename $attachment
}

set exception_count 0
set exception_text ""

if { $n_bytes == 0 } {
    append exception_text "<li>You haven't uploaded a file.\n"
    incr exception_count
}

if { ![empty_string_p [ad_parameter MaxAttachmentSize "comments"]] && $n_bytes > [ad_parameter MaxAttachmentSize "comments"] } {
    append exception_text "<li>Your file is too large.  The publisher of [ad_system_name] has chosen to limit attachments to [util_commify_number [ad_parameter MaxAttachmentSize "comments"]] bytes.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if { $inline_image_p == "f" } {
    set QQdisplay ""
}

ns_ora blob_dml_file $db "
    insert into wp_attachments(attach_id, slide_id, attachment, file_size, file_name, mime_type, display)
    values(wp_ids.nextval, $slide_id, empty_blob(), $n_bytes, '[DoubleApos $client_filename]', '$guessed_file_type', '$QQdisplay')
    returning attachment into :1
" $tmp_filename

ad_returnredirect "slide-attach.tcl?slide_id=$slide_id"
