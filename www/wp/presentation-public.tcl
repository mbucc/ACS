# $Id: presentation-public.tcl,v 3.0.4.1 2000/04/28 15:11:40 carsten Exp $
# File:        presentation-public.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Makes a presentation (non-)public.
# Inputs:      presentation_id, public_p

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

ns_db dml $db "update wp_presentations set public_p='$QQpublic_p' where presentation_id = $presentation_id"
ad_returnredirect "presentation-acl.tcl?presentation_id=$presentation_id"
