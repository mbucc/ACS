# $Id: outline-adjust-2.tcl,v 3.0.4.1 2000/04/28 15:11:40 carsten Exp $
# File:        outline-adjust-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Saves changes made to the outline.
# Inputs:      presentation_id, context_break_after, include_in_outline

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "write"

set context_break_after [util_GetCheckboxValues [ns_getform] context_break_after -1]
set include_in_outline [util_GetCheckboxValues [ns_getform] include_in_outline -1]

foreach i $context_break_after {
    wp_check_numeric $i
}
foreach i $include_in_outline {
    wp_check_numeric $i
}

# All in one DML! Yeah, baby!
ns_db dml $db "
    update wp_slides
    set context_break_after_p = decode((select 1 from dual where slide_id in ([join $context_break_after ","])), 1, 't', 'f'),
        include_in_outline_p = decode((select 1 from dual where slide_id in ([join $include_in_outline ","])), 1, 't', 'f')
    where presentation_id = $presentation_id
"

ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id"
