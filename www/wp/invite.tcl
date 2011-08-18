# $Id: invite.tcl,v 3.1 2000/03/11 17:45:14 jsalz Exp $
# File:        presentation-acl-add.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Allows an administrator to invite someone to read/write/admin a presentation.
# Inputs:      presentation_id, role

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

ReturnHeaders
ns_write "[wp_header_form "action=invite-2.tcl method=post" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl.tcl?presentation_id=$presentation_id" "Authorization"] "Invite User"]

[export_form_vars presentation_id role]

<p>
<table border=2 cellpadding=10><tr><td>
<table>
  <tr><td colspan=2>Please provide the name and E-mail address of the person whom you want to invite to
[wp_role_predicate $role], and we'll send an E-mail inviting him or her to do so, and describing how
to register with [ad_system_name]. The E-mail will appear to come from you, and you'll receive a copy.</P><hr></td></tr>
  <tr><th align=right>Name:&nbsp;</th><td><input name=name size=40></td></tr>
  <tr><th align=right>E-mail:&nbsp;</th><td><input name=email size=40></td></tr>
  <tr valign=top><th align=right><br>Message:&nbsp;</th><td><textarea name=message rows=6 cols=40></textarea><br><i>If you like, you can provide a brief message to include in the invitation E-mail.</i></td></tr>
  <tr><td colspan=2 align=center><hr><input type=submit value=\"Send Invitation E-Mail\"></td></tr>
</table></td></tr></table></p>

[wp_footer]
"
