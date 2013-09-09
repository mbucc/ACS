# /wp/style-delete.tcl

ad_page_contract {
    Description: Confirms that the user wants to delete the style.

    @param style_id

    @creation-date  28 Nov 1999
    @author Jon Salz (jsalz@mit.edu)
    @cvs-id style-delete.tcl,v 3.0.12.7 2000/09/22 01:39:36 kevin Exp
} {
    style_id:naturalnum,notnull
}

# everything for an old slide

set user_id [ad_maybe_redirect_for_registration]

wp_check_style_authorization $style_id $user_id

# Get the style information to display a confirmation message.
db_1row wp_style_name_select "select name from wp_styles where style_id = :style_id"

set num_images [db_string wp_image_count_select "select count(*) from wp_style_images where style_id = :style_id"]
if { $num_images == 0 } {
    set images_str ""
} elseif { $num_images == 1 } {
    set images_str "and the associated image"
} else {
    set images_str ", including $num_images associated images"
}


doc_return  200 text/html "
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

