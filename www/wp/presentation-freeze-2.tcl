# $Id: presentation-freeze-2.tcl,v 3.0.4.1 2000/04/28 15:11:40 carsten Exp $
# File:        presentation-freeze-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Freezes the current slide set.
# Inputs:      presentation_id, description

set_the_usual_form_variables

set db [ns_db gethandle]

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

# Do it all in PL/SQL.
ns_db dml $db "begin wp_set_checkpoint($presentation_id, '$QQdescription'); end;"

ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id"
