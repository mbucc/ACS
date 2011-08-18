# $Id: slide-attach-move.tcl,v 3.0.4.1 2000/04/28 15:11:41 carsten Exp $
# File:        slide-attach-move.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Changes the display mode for an attachment.
# Inputs:      attach_id, display

set_the_usual_form_variables
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

set selection [ns_db 1row $db "
    select s.presentation_id, s.slide_id
    from   wp_slides s, wp_attachments a
    where  a.attach_id = [wp_check_numeric $attach_id]
    and    s.slide_id = a.slide_id
"]
set_variables_after_query
wp_check_authorization $db $presentation_id $user_id "write"

ns_db dml $db "
    update wp_attachments
    set display = '$QQdisplay'
    where attach_id = $attach_id
"

ad_returnredirect "slide-attach.tcl?slide_id=$slide_id"
