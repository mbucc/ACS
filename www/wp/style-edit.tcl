# /wp/style-edit.tcl
ad_page_contract {
    Allows the user to create or edit a style.
    @cvs-id style-edit.tcl,v 3.0.12.12 2001/01/12 00:54:53 khy Exp
    @creation-date  28 Nov 1999
    @author  Jon Salz <jsalz@mit.edu>
    @param style_id ID of the style to edit (if editing)
    @param presentation_id ID of the presentation, if we should set a presentation to have this style
} {
    style_id:naturalnum,optional
    presentation_id:naturalnum,optional
}
# modified by jwong@arsdigita.com on 10 Jul 2000 for ACS 3.4 upgrades 

set user_id [ad_maybe_redirect_for_registration]

proc_doc wp_check_style_authorization { style_id user_id } { Verifies that the user owns this style. } {
    wp_check_numeric $style_id
    wp_check_numeric $user_id
    set owner [db_string wp_style_owner_select "select owner from wp_styles where style_id = :style_id" -default "not_found"]
    if { $owner == "not_found" } {
	set err "Error"
	set errmsg "Style $style_id was not found in the database."
    } else { 
	set err "Authorization Failed"
	set errmsg "You do not have the proper authorization to access this feature."
    }
    if { $owner != $user_id } {
	ad_return_error $err $errmsg
	ad_script_abort
    }
}

if { [info exists style_id] } {
    # Editing an existing style. Make sure we own it, and then retrieve info from the
    # database.
    wp_check_style_authorization $style_id $user_id

    db_1row style_select "
    select  name,
	    css, 
	    text_color, 
	    background_color,
	    background_image,
	    link_color,
	    alink_color,
	    vlink_color
    from wp_styles where style_id = :style_id" 

    set header [list "style-view.tcl?style_id=$style_id" $name]

    set role "Edit"
} else {
    # Creating a new style. Set fields to defaults.
    set show_modified_p "f"
    set public_p "t"
    set style -1
    foreach var { name description header text_color background_color background_image link_color alink_color vlink_color css } {
	set $var ""
    }

    set role "Create"
}

set colors { Chartreuse Mauve Teal Oyster Cordova Burgundy Spruce }
set elements { Polka-Dots Hearts {Maple Leaves} Peacocks Bunnies }

if { [info exists style_id] } {
    set items [db_list wp_file_names_select "
        select file_name
        from wp_style_images
        where style_id = :style_id
        order by file_name
    " ]
} else {
    set items ""
}


db_release_unused_handles

if { $items == "" } {
    set background_images "<i>There are not yet any uploaded images to use as the background.</i>
<input type=hidden name=background_image value=\"\">
"
} else {
    set values $items

    lappend items "none"
    lappend values ""

    set background_images "<select name=background_image>
[ad_generic_optionlist $items $values $background_image]</select>\n"
}

set values [list]


set page_output "[wp_header_form "name=f action=style-edit-2.tcl method=post enctype=multipart/form-data" \
           [list "" "WimpyPoint"] [list "style-list.tcl" "Your Styles"] $header "$role Style"]
[export_form_vars presentation_id]
[export_form_vars -sign style_id]
<script language=javascript>
[ad_color_widget_js]
</script>

<p><center>
<table border=2 cellpadding=10><tr><td>

<table cellspacing=0 cellpadding=0>
  <tr valign=baseline>
    <th nowrap align=right>Name:&nbsp;</th>
    <td><input type=text name=name size=50 value=\"[philg_quote_double_quotes $name]\"><br>
<i>A descriptive name, like \"[lindex $colors [randomRange [llength $colors]]] on [lindex $colors [randomRange [llength $colors]]] with [lindex $elements [randomRange [llength $elements]]]\".
  </tr>
  <tr>
    <th nowrap align=right>Text Color:&nbsp;</th>
    <td>[ad_color_widget text_color $text_color 1]</td>
  </tr>
  <tr>
    <th nowrap align=right>Background Color:&nbsp;</th>
    <td>[ad_color_widget background_color $background_color 1]</td>
  </tr>
  <tr>
    <th nowrap align=right>Background Image:&nbsp;</th>
    <td>$background_images</td>
  </tr>
  <tr>
    <th nowrap align=right>Link Color:&nbsp;</th>
    <td>[ad_color_widget link_color $link_color 1]</td>
  </tr>
  <tr>
    <th nowrap align=right>Visited Link Color:&nbsp;</th>
    <td>[ad_color_widget vlink_color $vlink_color 1]</td>
  </tr>
  <tr>
    <th nowrap align=right>Active Link Color:&nbsp;</th>
    <td>[ad_color_widget alink_color $alink_color 1]</td>
  </tr>
  <tr>
    <th nowrap align=right valign=top><br>CSS Source:&nbsp;</th>
    <td><textarea name=css rows=15 cols=60>[philg_quote_double_quotes $css]</textarea></td>
  </tr>
  <tr><td colspan=2 align=center><hr><input type=submit value=\"Save Style\"></td></tr>
</table>

</td></tr></table>

</center></p>

[wp_footer]
"

doc_return  200 "text/html" $page_output

