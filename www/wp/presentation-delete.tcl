# $Id: presentation-delete.tcl,v 3.0 2000/02/06 03:55:16 ron Exp $
# File:        presentation-delete.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Confirms the deletion of a presentation, requiring the user to enter
#              his password.
# Inputs:      presentation_id

set_the_usual_form_variables

set db [ns_db gethandle]

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

ReturnHeaders
ns_write "[wp_header_form "method=post action=presentation-delete-2.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] "Delete Presentation"]
[export_form_vars presentation_id]

Do you really want to delete $title?
All [database_to_tcl_string $db "select count(*) from wp_slides where presentation_id = $presentation_id"] slides will be permanently deleted.

<p>If you're really sure, please reenter your password.

<p><b>Password:</b> <input type=password size=20 name=password> <input type=submit value=\"Delete Presentation\">

</p>
[wp_footer]
"

