# $Id: presentation-acl-delete.tcl,v 3.0 2000/02/06 03:55:11 ron Exp $
# File:        presentation-acl-delete.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Deletes a user's ACL entry (after confirming).
# Inputs:      presentation_id, user_id

set_the_usual_form_variables
set req_user_id $user_id

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

set name [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = [wp_check_numeric $req_user_id]"]

ReturnHeaders
ns_write "[wp_header_form "action=presentation-acl-delete-2.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl.tcl?presentation_id=$presentation_id" "Authorization"] "Confirm Delete User"]

[export_form_vars presentation_id req_user_id]

<p>Are you sure you want to strip $name's access to $title?
[wp_only_if { $public_p == "t" } "The presentation is public, so the user will still be able to view it."]

<p><center>
<input type=button value=\"No, I want to cancel.\" onClick=\"location.href='presentation-acl.tcl?presentation_id=$presentation_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, proceed.\">
</p></center>

[wp_footer]
"
