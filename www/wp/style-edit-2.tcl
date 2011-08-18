# $Id: style-edit-2.tcl,v 3.0.4.1 2000/04/28 15:11:42 carsten Exp $
# File:        style-new-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Create or apply changes to a style.
# Inputs:      style_id (if editing), css (file), presentation_id

set user_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables

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

set db [ns_db gethandle]

if { [info exists style_id] } {
    set condition "style_id = $style_id"

    # If editing, make sure we can write to the style.
    wp_check_style_authorization $db $style_id $user_id
} else {
    set condition ""
    set style_id [wp_nextval $db "wp_ids"]
}

ad_process_color_widgets text_color background_color link_color alink_color vlink_color

set names [list style_id name owner css text_color background_color background_image link_color alink_color vlink_color]
set values [list $style_id "'$QQname'" $user_id "empty_clob()" \
                 "'$text_color'" "'$background_color'" "'$background_image'" "'$link_color'" "'$alink_color'" "'$vlink_color'"]
set clobs [list [list "css" $css]]

ns_db dml $db "begin transaction"
wp_try_dml_or_break $db [wp_prepare_dml "wp_styles" $names $values $condition] $clobs
if { [info exists presentation_id] } {
    # We reached here through the "I'll upload my own" menu item in presentation-edit.tcl.
    # Set the presentation's style, now that we've created it.
    wp_check_authorization $db $presentation_id $user_id
    ns_db dml $db "update wp_presentations set style = $style_id where presentation_id = $presentation_id"
}
ns_db dml $db "end transaction"

ad_returnredirect "style-view.tcl?style_id=$style_id"
