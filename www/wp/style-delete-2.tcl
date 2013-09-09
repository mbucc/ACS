# /wp/style-delete-2.tcl

ad_page_contract {
    Description: Deletes the style.

    @param style_id is the ID of the style to delete

    @creation-date  28 Nov 1999
    @author Jon Salz (jsalz@mit.edu)
    @cvs-id style-delete-2.tcl,v 3.1.6.5 2000/08/16 21:49:44 mbryzek Exp
} {
    style_id:naturalnum,notnull
}

set user_id [ad_maybe_redirect_for_registration]

wp_check_style_authorization $style_id $user_id

db_dml wp_style_delete "delete from wp_styles where style_id = :style_id"

db_release_unused_handles

ad_returnredirect "style-list.tcl"

