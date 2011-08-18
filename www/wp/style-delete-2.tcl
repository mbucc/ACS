# $Id: style-delete-2.tcl,v 3.0.4.1 2000/04/28 15:11:42 carsten Exp $
# File:        slide-delete-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Deletes the style.
# Inputs:      style_id

set_the_usual_form_variables

# everything for an old slide
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

wp_check_style_authorization $db $style_id $user_id

ns_db dml $db "delete from wp_styles where style_id = $style_id"

ad_returnredirect "style-list.tcl"

