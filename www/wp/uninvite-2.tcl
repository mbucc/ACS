# $Id: uninvite-2.tcl,v 3.0.4.1 2000/04/28 15:11:42 carsten Exp $
# File:        uninvite.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Deletes a wp_user_access_ticket.
# Inputs:      presentation_id, invitation_id

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

ns_db dml $db "delete from wp_user_access_ticket where presentation_id = $presentation_id and invitation_id = [wp_check_numeric $invitation_id]"

ad_returnredirect "presentation-acl.tcl?presentation_id=$presentation_id"
