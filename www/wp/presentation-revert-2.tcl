# $Id: presentation-revert-2.tcl,v 3.0.4.1 2000/04/28 15:11:41 carsten Exp $
# File:        presentation-revert-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Reverts a presentation to a previous version.
# Inputs:      presentation_id, checkpoint

set_the_usual_form_variables

set db [ns_db gethandle]

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

ns_db dml $db "begin wp_revert_to_checkpoint($presentation_id, [wp_check_numeric $checkpoint]); end;"

ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id"
