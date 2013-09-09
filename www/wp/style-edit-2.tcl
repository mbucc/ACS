
# /wp/style-edit-2.tcl
ad_page_contract {
    Create or apply changes to a style.
    @cvs-id style-edit-2.tcl,v 3.2.2.16 2001/01/12 00:54:20 khy Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param name is the name of the style
    @param style_id is the ID of the style (if editing)
    @param presentation_id is the ID of the presentation to which the style is applied
    @param text_color.* are rgb values of text_color
    @param background_color.* are rgb values of background_color
    @param link_color.* are  rgb values of link_color
    @param css is the text of a cascading style sheet (file)
} {
    name:optional
    style_id:naturalnum,verify,optional
    presentation_id:naturalnum,optional
    text_color.c1:naturalnum,optional
    text_color.c2:naturalnum,optional
    text_color.c3:naturalnum,optional
    background_color.c1:naturalnum,optional
    background_color.c2:naturalnum,optional
    background_color.c3:naturalnum,optional
    background_image:optional
    link_color.c1:naturalnum,optional
    link_color.c2:naturalnum,optional
    link_color.c3:naturalnum,optional
    alink_color.c1:naturalnum,optional
    alink_color.c2:naturalnum,optional
    alink_color.c3:naturalnum,optional
    vlink_color.c1:naturalnum,optional
    vlink_color.c2:naturalnum,optional
    vlink_color.c3:naturalnum,optional
    css:optional
}
# modified by jwong@arsdigita.com on 10 Jul 2000 for ACS 3.4 upgrade

# check for naughty html
if { [info exists name] && ![empty_string_p [ad_check_for_naughty_html $name]] } {
    ad_return_complaint 1 "[ad_check_for_naughty_html $name]\n"
    return
}
if { [info exists css] && ![empty_string_p [ad_check_for_naughty_html $css]] } {
    ad_return_complaint 1 "[ad_check_for_naughty_html $css]\n"
    return
}

set user_id [ad_maybe_redirect_for_registration]

set exception_count 0
set exception_text ""

if { ![info exists name] || $name == "" } {
    append exception_text "<li>Please specify a name for your style."
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# We're OK to insert or update.

if { [info exists style_id] } {
    set condition "style_id = [wp_check_numeric $style_id]"

    # If editing, make sure we can write to the style.
    wp_check_style_authorization $style_id $user_id
} else {
    set condition ""
    set style_id [wp_nextval "wp_ids"]
}

ad_process_color_widgets text_color background_color link_color alink_color vlink_color

set names [list style_id name owner css text_color background_color background_image link_color alink_color vlink_color]
set values [list $style_id $name $user_id empty_clob() \
                 $text_color $background_color $background_image $link_color $alink_color $vlink_color]
set clobs [list [list "css" $css]]


db_transaction {
    wp_try_dml_or_break [wp_prepare_dml "wp_styles" $names $values $condition] $clobs
    if { [info exists presentation_id] } {
	# We reached here through the "I'll upload my own" menu item in presentation-edit.tcl.
	# Set the presentation's style, now that we've created it.
	wp_check_authorization $presentation_id $user_id
	
	db_dml pres_update "update wp_presentations set style = :style_id where presentation_id = :presentation_id"
    }
} on_error {
    db_release_unused_handles
    ad_return_error "Error" "Couldn't update your style."
}

db_release_unused_handles

ad_returnredirect "style-view?[export_url_vars style_id presentation_id]"
