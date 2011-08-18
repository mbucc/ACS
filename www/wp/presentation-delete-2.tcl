# $Id: presentation-delete-2.tcl,v 3.0 2000/02/06 03:55:14 ron Exp $
# File:        presentation-delete-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Deletes a presentation.
# Inputs:      presentation_id, password

set_the_usual_form_variables

set db [ns_db gethandle]

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

if { $password != [database_to_tcl_string $db "select password from users where user_id = $user_id"] } {
    ad_return_complaint 1 "<li>The password you entered is incorrect.\n"
    return
}

ns_db dml $db "begin transaction"

ns_db dml $db "delete from wp_presentations where presentation_id = $presentation_id"
ns_db dml $db "delete from user_groups where group_type = 'wp' and group_name = '$presentation_id'"

ns_db dml $db "end transaction"

ReturnHeaders
ns_write "[wp_header_form "name=f" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] "Presentation Deleted"]

The presentation has been deleted.

<p><a href=\"\">Return to your presentations</a>
</p>

[wp_footer]
"

