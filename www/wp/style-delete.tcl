# $Id: style-delete.tcl,v 3.0 2000/02/06 03:55:43 ron Exp $
# File:        slide-delete.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Confirms that the user wants to delete the style.
# Inputs:      style_id

set_the_usual_form_variables

# everything for an old slide
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

# Get the style information to display a confirmation message.
set selection [ns_db 1row $db "select * from wp_styles where style_id = [wp_check_numeric $style_id]"]
set_variables_after_query
wp_check_style_authorization $db $style_id $user_id

set num_images [database_to_tcl_string $db "select count(*) from wp_style_images where style_id = $style_id"]
if { $num_images == 0 } {
    set images_str ""
} elseif { $num_images == 1 } {
    set images_str "and the associated image"
} else {
    set images_str ", including $num_images associated images"
}

ReturnHeaders
ns_write "
[wp_header_form "action=style-delete-2.tcl" [list "" "WimpyPoint"] [list "style-list.tcl" "Your Styles"] "Delete $name"]
[export_form_vars style_id]

Are you sure that you want to delete the style $name$images_str?

<p><center>
<input type=button value=\"No, I want to cancel.\" onClick=\"location.href='style-list.tcl'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, proceed.\">
</p></center>

[wp_footer]
"

