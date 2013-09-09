# /wp/slide-attach-2.tcl

ad_page_contract {
    Adds an attachment.

    @param slide_id the slide to which to attach the file
    @param attachment the file to attach
    @param inline_image_p is this an inline image
    @param display

    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id slide-attach-2.tcl,v 3.2.2.6 2000/09/05 18:56:16 tina Exp
} {
    slide_id:naturalnum,notnull
    attachment:notnull
    inline_image_p:notnull
    display:notnull
}

set user_id [ad_maybe_redirect_for_registration]

db_1row wp_pres_id_select "
select presentation_id from wp_slides where slide_id = :slide_id"

wp_check_authorization $presentation_id $user_id "write"

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
    set display ""
}

db_dml wp_insert_attachment "
    insert into wp_attachments(attach_id, slide_id, attachment, file_size, file_name, mime_type, display)
    values(wp_ids.nextval, :slide_id, empty_blob(), :n_bytes, :client_filename, :guessed_file_type, :display)
    returning attachment into :1
" -blob_files $tmp_filename

db_release_unused_handles

ad_returnredirect "slide-attach.tcl?slide_id=$slide_id"
