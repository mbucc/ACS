# /wp/slide-attach.tcl

ad_page_contract {
    Allows the user to add and delete attachments.

    @param slide_id the slide to which to attach

    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id slide-attach.tcl,v 3.2.2.6 2000/09/22 01:39:35 kevin Exp
} {
    slide_id:naturalnum,notnull
}

set user_id [ad_maybe_redirect_for_registration]

db_1row wp_slide_attach_slide_info "
select presentation_id, title from wp_slides where slide_id = :slide_id"

wp_check_authorization $presentation_id $user_id "write"

append whole_page "
[wp_header_form "enctype=multipart/form-data action=slide-attach-2.tcl method=post" [list "" "WimpyPoint"] \
  [list "index.tcl?show_user=" "Your Presentations"] \
  [list "presentation-top.tcl?presentation_id=$presentation_id" [db_string wp_prsent_title "select title from wp_presentations where presentation_id = :presentation_id"]] "Attachments to $title"]
[export_form_vars slide_id]

<center><p>
<table border=2 cellpadding=10><tr><td>
<table cellspacing=0 cellpadding=0>
<tr>
  <th align=left nowrap>File Name</th><td>&nbsp;&nbsp;&nbsp;</td>
  <th align=right nowrap>File Size</th><td>&nbsp;&nbsp;&nbsp;</td>
  <th nowrap>Display</th>
</tr>
<tr><td colspan=7><hr></td></tr>

"

set display_options {
    { "top" "at the very top (aligned center)" "Top" }
    { "preamble" "next to the preamble (aligned right)" "Preamble" }
    { "after-preamble" "after the preamble (aligned center)" "After Preamble" }
    { "bullets" "next to the bullets (aligned right)" "Bullets" }
    { "after-bullets" "after the bullets (aligned center)" "After Bullets" }
    { "postamble" "next to the postamble (aligned right)" "Postamble" }
    { "bottom" "at the very bottom (aligned center)" "Bottom" }
}

# Generates <option>s for a <select> list of $display_options. If $prompt == 1,
# uses the long description, or if $prompt == 2, uses the short description.
proc wp_attach_display_options { selected prompt } {
    upvar display_options display_options
    set out ""
    foreach opt $display_options {
	append out "<option value=[lindex $opt 0] [wp_only_if { [lindex $opt 0] == $selected } "selected"]>[lindex $opt $prompt]\n"
    }
    if { $prompt == 2 } {
	append out "<option value=\"\" [wp_only_if { $selected == "" } "selected"]>Linked\n"
    }
    return $out
}

# Generate the list of all attached images.
set out ""
db_foreach wp_img_sel "
    select attach_id, file_name, file_size, display
    from   wp_attachments
    where  slide_id = :slide_id
    order by lower(file_name)
" {
    append out "
<tr>
  <td><a href=\"[wp_attach_url]/$attach_id/$file_name\">$file_name</a></td><td></td>
  <td align=right>[format "%.1f" [expr { $file_size / 1024.0 }]]K</td><td></td>
  <td align=center nowrap><select onChange=\"location.href='slide-attach-move.tcl?attach_id=$attach_id&display='+options\[selectedIndex\].value\">
[wp_attach_display_options $display 2]
</select>
</td><td></td>
  <td>\[ <a href=\"slide-attach-delete?slide_id=$slide_id&attach_id=$attach_id\">delete</a> \]</td>
</tr>
"
} else {
    append out "<tr><td colspan=7 align=center><i>There are no attachments currently associated with this slide.</i></td></tr>\n"
}

append whole_page "$out

  <tr valign=top><td colspan=7>
    <center>
      <br><a href=\"[wp_presentation_url]/$presentation_id/$slide_id.wimpy\" target=\"_blank\">Preview the Slide</a>
    </center>
    </p>
    <hr>
    <center>
      <br><b>Add an Image or Attachment:</b>
      <p><input type=file size=30 name=attachment>
    </center>
    <p><input type=radio name=inline_image_p value=t checked> Display as an image
<select name=display>
[wp_attach_display_options "preamble" 1]
</select>
      <br><input type=radio name=inline_image_p value=f> Display a link the viewer can use to download the file
      <center>
      <p><input type=submit value=\"Add the Attachment\">
    </td>
    </tr></table>
  </td></tr>
</table>
</td></tr></table>
</p></center>

[wp_footer]
"


doc_return  200 text/html $whole_page