# $Id: reorder-slides-2.tcl,v 3.0.4.1 2000/04/28 15:11:41 carsten Exp $
# File:        reorder-slides-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Saves changes made to slide order.
# Inputs:      presentation_id, slide_id

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "write"

# Just iterate over the values for slide_id in order and set their respective
# sort_keys to 1, 2, 3, ...
set counter 0
foreach slide [util_GetCheckboxValues [ns_getform] slide_id] {
    incr counter
    ns_db dml $db "
        update wp_slides
        set    sort_key = $counter
        where  slide_id = $slide
        and    presentation_id = $presentation_id
    "
}

ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id"

