# $Id: style-image-add.tcl,v 3.0.4.1 2000/04/28 15:11:42 carsten Exp $
# File:        style-image-add.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Add an image.
# Inputs:      style_id, image

set user_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables

set exception_count 0
set exception_text ""

set tmp_filename [ns_queryget image.tmpfile]
set guessed_file_type [ns_guesstype $image]
set n_bytes [file size $tmp_filename]

# strip off the C:\directories... crud and just get the file name
if ![regexp {([^/\\]+)$} $image match client_filename] {
    set client_filename $image
}

set exception_count 0
set exception_text ""

if { $n_bytes == 0 && ![info exists style_id] } {
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

# We're OK to insert. We'll always do a delete, then an insert, in case we're overwriting
# an existing image with the same name.

set db [ns_db gethandle]

wp_check_style_authorization $db $style_id $user_id

ns_db dml $db "begin transaction"
ns_db dml $db "delete from wp_style_images where style_id = $style_id and file_name = '[DoubleApos $client_filename]'"
ns_ora blob_dml_file $db "
    insert into wp_style_images(style_id, image, file_size, file_name, mime_type)
    values($style_id, empty_blob(), $n_bytes, '[DoubleApos $client_filename]', '$guessed_file_type')
    returning image into :1
" $tmp_filename
ns_db dml $db "end transaction"

ad_returnredirect "style-view.tcl?style_id=$style_id"
