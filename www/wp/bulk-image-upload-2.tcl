# File:        bulk-image-upload-2.tcl
# Date:        03 Mar 2000
# Author:      Nuno Santos <nuno@arsdigita.com>
# Description: Adds slides/images to presentation (from an uploaded set of zipped GIFs, PNGs and/or JPGs).
# Inputs:      attachment (file), presentation_id

set_the_usual_form_variables

wp_check_numeric $presentation_id

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

wp_check_authorization $db $presentation_id $user_id "write"

set tmp_filename [ns_queryget attachment.tmpfile]
set n_bytes [file size $tmp_filename]

set exception_count 0
set exception_text ""

if { $n_bytes == 0 } {
    append exception_text "<li>You haven't uploaded a file.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}


# unpack the ZIP file into a directory of its own.
set dir [file dirname $tmp_filename]
cd $dir
set temp_dir [ns_mktemp "$presentation_id-XXXXXX"]
if [catch { ns_mkdir $temp_dir } errmsg ] {
    ad_return_error "Can't create directory" "The directory 
        for unzipping this image archive could not be created.
        <br> Hit back in your browser and refresh the previous page 
        in order to upload another archive. 
        <p> Here is the exact error message: <pre>$errmsg</pre></li>"

    return
}

cd $temp_dir
append dir "/$temp_dir"

set unzip [ad_parameter "PathToUnzip" "wp" "/usr/bin/unzip"]

# unzip -C -j zipfile *.gif *.jpg *.png -d directory
# only extract GIFs, PNGs and JPGs (-C=case-insensitive) into directory; don't create subdirs (-j);
# ignore "caution: filename not matched" unzip message (if one of the formats is not present in the archive)
if {[catch { exec $unzip -C -j $tmp_filename *.gif *.jpg *.png -d $dir } errmsg] 
    && ![regexp {caution: filename not matched} $errmsg]} {
    ad_return_error "Can't unzip file" "The file you uploaded could not be unzipped.
        The most likely reason for this is that the file is not a valid ZIP format file.
        <br>Hit back in your browser, create a proper ZIP file and try uploading again.
        <p>Here is the exact error message: <pre>$errmsg</pre></li>"

    # cleanup
    cd ..
    exec rm -fr $temp_dir

    return
}


set title [database_to_tcl_string $db "select title from wp_presentations where presentation_id = $presentation_id"]

set html_page "[wp_header_form "action=bulk-copy-3.tcl" \
                [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
                [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] \
                [list "bulk-image-upload.tcl?presentation_id=$presentation_id" "Upload Image Archive"] "Uploading Slides"]

Creating slides...
<ul>
"

set sort_key [database_to_tcl_string $db "select nvl(max(sort_key), 0)
                                          from wp_slides
                                          where presentation_id = $presentation_id"]
set checkpoint [database_to_tcl_string $db "select max(checkpoint) 
                                            from wp_checkpoints 
                                            where presentation_id = $presentation_id"]

ns_db dml $db "begin transaction"

# create slides from the image files (valid extensions: gif, jpg, png; case insensitive)
set image_files [glob -nocomplain {*.{[Gg][Ii][Ff],[Jj][Pp][Gg],[Pp][Nn][Gg]}}]
foreach image $image_files {
    incr sort_key

    set image_bytes [file size $image]

    # slide title = filename (without extension)
    set extension_length [string length [file extension $image]]
    set slide_title [string range $image 0 [expr [string length $image] - $extension_length - 1]]
    set slide_id [wp_nextval $db "wp_ids"]

    append html_page "<li> $slide_title... \n"

    # create the slide
    ns_db dml $db "
        insert into wp_slides
        (slide_id, presentation_id, modification_date, sort_key, 
         min_checkpoint, title, preamble, bullet_items, postamble, original_slide_id)
        values
        ($slide_id, $presentation_id, sysdate, $sort_key, 
         $checkpoint, '[DoubleApos $slide_title]', empty_clob(), empty_clob(), empty_clob(), null)"

    set guessed_file_type [ns_guesstype $image]

    # uploaded images always go after the preamble, centered
    set display "after-preamble"

    # attach the image to the slide
    ns_ora blob_dml_file $db "
        insert into wp_attachments
        (attach_id, slide_id, attachment, file_size, file_name, mime_type, display)
        values
        (wp_ids.nextval, $slide_id, empty_blob(), $image_bytes, '[DoubleApos $image]', '$guessed_file_type', '$display')
        returning attachment into :1" $image

    ns_unlink $image
}

ns_db dml $db "end transaction"

ns_db releasehandle $db


append html_page "<li>Finished.
<p><a href=\"presentation-top.tcl?presentation_id=$presentation_id\">Return to $title</a>
</ul>
[wp_footer]
"

ns_return 200 "text/html" $html_page


# cleanup
cd ..
exec rm -fr $temp_dir
















