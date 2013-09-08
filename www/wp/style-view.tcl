# /wp/style-view.tcl
ad_page_contract {
    Allows the user to view a style.
    @cvs-id style-view.tcl,v 3.4.2.12 2000/09/22 01:39:37 kevin Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param style_id (if editing)
    @param presentation_id (if we were editing a presentation)
} {
    style_id:integer,optional
    presentation_id:naturalnum,optional
}
# modified by jwong@arsdigita.com on 10 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]

wp_check_style_authorization $style_id $user_id

db_1row style_select "
select name, 
	css, 
	text_color, 
	background_color,
	background_image,
	link_color,
	alink_color,
	vlink_color 
from wp_styles where style_id = :style_id"

if { $background_color == "" } {
    set bgcolor_str ""
} else {
    set bgcolor_str "bgcolor=[ad_color_to_hex $background_color]"
}
if { $background_image == "" } {
    set bgimage_str ""
} else {
    set bgimage_str "style=\"background-image: url([wp_style_url]/$style_id/$background_image)\""
}

foreach property { text_color link_color alink_color vlink_color } {
    if { [set $property] == "" } {
	set "${property}_font" ""
	set "${property}_font_end" ""
    } else {
	set "${property}_font" "<font color=[ad_color_to_hex [set $property]]>"
	set "${property}_font_end" "</font>"
    }
}

# set the return link to the presentation we were editing, if id exists
if { [exists_and_not_null presentation_id] } {
    set last_link " [list "presentation-top?presentation_id=$presentation_id" "[db_string pres_name_select "select title from wp_presentations where presentation_id = :presentation_id"]"]"
} else {
set last_link [list "style-list?user_id=$user_id" "Your Styles"]
}

set page_output "[wp_header_form "name=f action=style-image-add method=post enctype=multipart/form-data" \
	[list "" "WimpyPoint"] $last_link $name]
[export_form_vars style_id presentation_id]

<p><center>
<table border=2 cellpadding=10><tr><td>

<table cellspacing=0 cellpadding=0>
  <tr valign=baseline>
    <th nowrap align=right>Name:&nbsp;</th>
    <td colspan=5>$name</td>
  </tr>
  <tr valign=top>
    <th nowrap align=right><br>Color Scheme:&nbsp;</th>
    <td colspan=5>
      <table border=2 $bgcolor_str cellpadding=10>
        <tr><td $bgimage_str>
          ${text_color_font}Plain Text$text_color_font_end<br>
          ${link_color_font}<u>Linked Text</u>$link_color_font_end<br>
          ${vlink_color_font}<u>Linked Text (Visited)</u>$alink_color_font_end<br>
          ${alink_color_font}<u>Linked Text (Active)</u>$vlink_color_font_end
        </td></tr>
      </table>
    </td>
  <tr>
    <th nowrap align=right>CSS Code:&nbsp;</th>
      <td colspan=5>[expr { [regexp {[^ \n\r\t]} $css] ? "<a href=\"css-view?style_id=$style_id\">view</a>" : "none" }]</td>
  </tr>
  <tr>
    <td align=center colspan=5><br><input type=button onClick=\"location.href='style-edit?[export_url_vars style_id presentation_id]'\" value=\"Edit Style\"><hr></td>
  </tr>
"

set counter 0
set out ""
db_foreach style_image_select "
    select file_size, file_name
    from   wp_style_images
    where  style_id = :style_id
    order by file_name
" {
    incr counter
    append out "<tr><th>"
    if { $counter == 1 } {
	append out "Images:&nbsp;"
    }
    append out "</th><td><a href=\"[wp_style_url]/$style_id/$file_name\">$file_name</a></td><td>&nbsp;</td>
<td align=right>[format "%.1f" [expr $file_size / 1024.0]]K&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
<td align=right><a href=\"style-image-delete?style_id=$style_id&file_name=[ns_urlencode $file_name]\">delete</a></td>
</tr>
"
} if_no_rows {
    append out "<tr><th align=right>Images:&nbsp;</th><td>(none)</td></tr>\n"
}

db_release_unused_handles

append page_output "$out
  <tr>
    <td colspan=5 align=center>
      <br><br><b>Add an image:</b><br>
      <input name=image type=file size=30><br>
      <p><input type=submit value=\"Save Image\">
    </td>
  </tr>
</table>

</td></tr></table>

</center></p>

[wp_footer]
"

doc_return  200 "text/html" $page_output

