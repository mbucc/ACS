# /www/wp/bulk-image-upload-2.tcl

ad_page_contract {

    Adds slides/images to presentation (from an uploaded set of zipped
    GIFs, PNGs and/or JPGs). 

    @param presentation_id 
    @param attachment 
    
    @author Nuno Santos <nuno@arsdigita.com>
    @creation-date 
    @cvs-id bulk-image-upload-2.tcl,v 3.8.2.7 2000/09/22 01:39:29 kevin Exp
} {
    {presentation_id:naturalnum,notnull}
    {attachment:html,notnull}
}

set user_id [ad_maybe_redirect_for_registration]

wp_check_authorization $presentation_id $user_id "write"

set tmp_filename [ns_queryget attachment.tmpfile]
set n_bytes      [file size $tmp_filename]

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

set temp_dir [file dirname $tmp_filename]
append temp_dir "/[ns_mktemp "$presentation_id-XXXXXX"]"
if [catch { ns_mkdir $temp_dir } errmsg ] {
    ad_return_error "Can't create directory" "The directory 
    for unzipping this image archive could not be created.
    <br> Hit back in your browser and refresh the previous page 
    in order to upload another archive. 
    <p> Here is the exact error message: <pre>$errmsg</pre></li>"

    return
}

set unzip [ad_parameter "PathToUnzip" "wp" "/usr/bin/unzip"]

# unzip -C -j zipfile *.gif *.jpg *.png -d directory
# only extract GIFs, PNGs and JPGs (-C=case-insensitive) into
# directory; don't create subdirs (-j); 
# ignore "caution: filename not matched" unzip message (if one of the
# formats is not present in the archive) 

if {[catch { exec $unzip -C -j $tmp_filename *.gif *.jpg *.png -d $temp_dir } errmsg] 
    && ![regexp {caution: filename not matched} $errmsg]} {
	ad_return_error "Can't unzip file" "The file you uploaded could not be unzipped.
        The most likely reason for this is that the file is not a valid ZIP format file.
        <br>Hit back in your browser, create a proper ZIP file and try uploading again.
        <p>Here is the exact error message: <pre>$errmsg</pre></li>"
	# cleanup
	exec rm -rf $temp_dir
    return
}

set title [db_string wp_sel_title "select title from wp_presentations where presentation_id = :presentation_id"]

set html_page "
[wp_header_form "action=bulk-copy-3" \
	[list "" "WimpyPoint"] \
	[list "index?show_user=" "Your Presentations"] \
	[list "presentation-top?presentation_id=$presentation_id" "$title"] \
	[list "bulk-image-upload?presentation_id=$presentation_id" "Upload Image Archive"] \
	"Uploading Slides"]

Creating slides...
<ul>
"

set sort_key [db_string wp_sel_sort_key "
select nvl(max(sort_key), 0)
from   wp_slides
where  presentation_id = :presentation_id"]

set checkpoint [db_string wp_sel_ckpt "
select max(checkpoint) 
from   wp_checkpoints 
where  presentation_id = :presentation_id"]

# create slides from the image files (valid extensions: gif, jpg, png; case insensitive)

set file_exts {[Gg][Ii][Ff],[Jj][Pp][Gg],[Pp][Nn][Gg]}
set image_files [glob -nocomplain $temp_dir/*.{$file_exts}]

# sort file list (if filenames have a number somewhere)

set image_files [wp_numeric_sort_bulk_slides $image_files]

db_transaction {

    foreach image $image_files {
	incr sort_key

	set image_bytes [file size $image]

	# slide title = filename (without extension)
	set image_base       [file tail $image]
	set extension_length [string length [file extension $image_base]]
	set slide_title      [string range $image_base 0 [expr [string length $image_base] - $extension_length - 1]]
	set slide_id         [wp_nextval "wp_ids"]

	append html_page "<li> $slide_title... \n"

	# create the slide
	db_dml wp_create_1st_slide "
        insert into wp_slides
        (slide_id, 
	 presentation_id, 
	 modification_date, 
	 sort_key, 
	 min_checkpoint, 
	 title, 
	 preamble, 
	 bullet_items, 
	 postamble, 
	 original_slide_id)
        values
        (:slide_id, 
	 :presentation_id, 
          sysdate, 
         :sort_key, 
	 :checkpoint, 
	 :slide_title, 
	 empty_clob(), empty_clob(), empty_clob(), '[db_null]')"

	set guessed_file_type [ns_guesstype $image]

	# uploaded images always go after the preamble, centered
	set display "after-preamble"
	
	# attach the image to the slide
	db_dml wp_attach_img "
        insert into wp_attachments
        (attach_id, 
	 slide_id, 
	 attachment, 
	 file_size, 
	 file_name, 
	 mime_type, 
	 display)
         values
        (wp_ids.nextval, 
	 :slide_id, 
	 empty_blob(), 
	 :image_bytes, 
	 :image_base, 
	 :guessed_file_type, 
	 :display)
         returning attachment into :1" -blob_files [list $image]

	ns_unlink $image
    }
}

append html_page "
<li>Finished.
<p><a href=presentation-top?presentation_id=$presentation_id>Return to $title</a>
</ul>
[wp_footer]
"

doc_return  200 text/html $html_page

# cleanup
# mbryzek - 5/27/2000
# Note that the tcl file delete command deletes recursively!
# We use -force to remove empty directories. This is much 
# better than exec' rm -fr $temp_dir

file delete -force $temp_dir




