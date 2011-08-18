# $Id: slide-delete-2.tcl,v 3.0.4.1 2000/04/28 15:11:41 carsten Exp $
# File:        slide-delete-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Deletes a slide.
# Inputs:      slide_id

set_the_usual_form_variables

# everything for an old slide
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

set presentation_id [database_to_tcl_string $db "select presentation_id from wp_slides where slide_id = [wp_check_numeric $slide_id]"]
wp_check_authorization $db $presentation_id $user_id "write"

ns_db dml $db "begin transaction"

# Remove it from the current view by setting its checkpoint value.
ns_db dml $db "
    update wp_slides
    set    max_checkpoint = (select max(checkpoint) from wp_checkpoints where presentation_id = $presentation_id)
    where  slide_id = $slide_id
    and    max_checkpoint is null
"
# If it's not remaining in any view, just delete it.
ns_db dml $db "
    delete from wp_slides
    where  slide_id = $slide_id
    and    max_checkpoint = min_checkpoint
"

ns_db dml $db "end transaction"

ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id"
