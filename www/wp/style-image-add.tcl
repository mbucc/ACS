# /wp/style-image-add.tcl
ad_page_contract {
    Add an image to a style.

    @param style_id id of the style to which to add
    @param image the image to add

    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id style-image-add.tcl,v 3.2.2.9 2000/09/05 18:53:47 tina Exp
} {
    style_id:naturalnum,notnull
    image:notnull
}

set user_id [ad_maybe_redirect_for_registration]

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



wp_check_style_authorization $style_id $user_id

db_transaction {
    db_dml wp_img_delete "delete from wp_style_images 
    where style_id = :style_id 
    and file_name = :client_filename"
    
    db_dml wp_style_img_insert "
    insert into wp_style_images(style_id, image, file_size, file_name, mime_type, wp_style_images_id)
    values(:style_id, empty_blob(), :n_bytes, 
    :client_filename, :guessed_file_type, wp_style_images_seq.nextval)
    returning image into :1
    " -blob_files [list $tmp_filename]
}

db_release_unused_handles

ad_returnredirect "style-view?style_id=$style_id"
