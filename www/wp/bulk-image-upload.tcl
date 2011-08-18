# File:        bulk-image-upload.tcl
# Date:        03 Mar 2000
# Author:      Nuno Santos <nuno@arsdigita.com>
# Description: Allows the user to bulk upload a presentation (from a set of zipped GIF, PNG and/or JPG files)
# Inputs:      presentation_id

set_the_usual_form_variables

wp_check_numeric $presentation_id

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "write"

set title [database_to_tcl_string $db "select title from wp_presentations where presentation_id = $presentation_id"]

ns_db releasehandle $db

ns_return 200 "text/html" "
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



