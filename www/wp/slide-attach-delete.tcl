# $Id: slide-attach-delete.tcl,v 3.0.4.1 2000/04/28 15:11:41 carsten Exp $
# File:        slide-attach-delete.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Deletes an attachment.
# Inputs:      slide_id, attach_id

set_the_usual_form_variables
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

set selection [ns_db 1row $db "select * from wp_slides where slide_id = $slide_id"]
set_variables_after_query
wp_check_authorization $db $presentation_id $user_id "write"

ns_db dml $db "delete from wp_attachments where attach_id = $attach_id and slide_id = $slide_id"

ad_returnredirect "slide-attach.tcl?slide_id=$slide_id"
