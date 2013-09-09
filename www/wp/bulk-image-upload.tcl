# /wp/bulk-image-upload.tcl

ad_page_contract {
    Allows the user to bulk upload a presentation  (from a set of zipped GIF, PNG and/or JPG files)

    @param presentation_id the presentation to which to upload images

    @creation-date  03 Mar 2000
    @author Nuno Santos <nuno@arsdigita.com>
    @cvs-id bulk-image-upload.tcl,v 3.3.2.7 2000/09/22 01:39:29 kevin Exp
} {
    presentation_id:naturalnum,notnull
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "write"

set title [db_string wp_title_select "select title from wp_presentations where presentation_id = :presentation_id"]

doc_return  200 "text/html" "
[wp_header_form "enctype=multipart/form-data action=\"bulk-image-upload-2.tcl?[export_url_vars presentation_id]\" method=post"  \
  [list "" "WimpyPoint"] \
  [list "index.tcl?show_user=" "Your Presentations"] \
  [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] "Upload Image Archive"]
[export_form_vars presentation_id]

To upload an archive of images, save your images as GIFs, JPGs or PNGs
(only these file formats are recognized and unpacked), pack them into a ZIP file and then upload the ZIP file. 
<p>Each image will be converted into a single WimpyPoint slide, with the title set to the image filename. 
<br>The new slides will be added at the end of $title.
You can always adjust the order of the slides, edit their titles and add further text later.

<center><p>
<table border=2 cellpadding=10>
<tr><td>
    <center>
      <br><b>Select the ZIP file to upload:</b>
      <p><input type=file size=30 name=attachment>
      <p><input type=submit value=\"Upload the image archive\">
    </center>
    </td>
    </tr>
</table>
</p></center>

[wp_footer]
"
