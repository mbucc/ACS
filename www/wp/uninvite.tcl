# $Id: uninvite.tcl,v 3.0 2000/02/06 03:55:51 ron Exp $
# File:        uninvite.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Deletes a wp_user_access_ticket (after confirming).
# Inputs:      presentation_id, invitation_id

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

set selection [ns_db 1row $db "
    select name, role
    from   wp_user_access_ticket
    where  invitation_id = [wp_check_numeric $invitation_id]
    and    presentation_id = $presentation_id
"]
set_variables_after_query

ReturnHeaders
ns_write "[wp_header_form "action=uninvite-2.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl.tcl?presentation_id=$presentation_id" "Authorization"] "Confirm Delete User"]

[export_form_vars presentation_id invitation_id]

<p>Are you sure you want to revoke $name's invitation to [wp_role_predicate $role $title]?

<p><center>
<input type=button value=\"No, I want to cancel.\" onClick=\"location.href='presentation-acl.tcl?presentation_id=$presentation_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, proceed.\">
</p></center>

[wp_footer]
"
