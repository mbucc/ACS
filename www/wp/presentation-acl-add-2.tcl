# $Id: presentation-acl-add-2.tcl,v 3.0 2000/02/06 03:55:07 ron Exp $
# File:        presentation-acl-add-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Adds a user to an ACL (after confirming).
# Inputs:      presentation_id, role, user_id_from_search, first_names_from_search, last_name_from_search

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

# Don't let the administrator add an equivalent or lower access level than was previously there.
if { [wp_access $db $presentation_id [wp_check_numeric $user_id_from_search] $role] != "" } {
    ad_return_error "User Already Had That Privilege" "
That user can already [wp_role_predicate $role]. Maybe you want to
<a href=\"presentation-acl.tcl?presentation_id=$presentation_id\">try again</a>.
"
    return
}

ReturnHeaders
ns_write "[wp_header_form "action=presentation-acl-add-3.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl.tcl?presentation_id=$presentation_id" "Authorization"] "Confirm Add User"]

[export_form_vars presentation_id user_id_from_search first_names_from_search last_name_from_search role]

<p>Are you sure you want to give $first_names_from_search $last_name_from_search permission to [wp_role_predicate $role $title]?

<blockquote>
<table cellspacing=0 cellpadding=0><tr valign=baseline>
<td><input name=email type=checkbox select>&nbsp;</td>
<td>Send an E-mail message to $first_names_from_search with a link to the presentation.<br>Include
the following message (optional):
<br>
<textarea name=message rows=5 cols=40></textarea>
</td></tr></table>
</blockquote>

<p><center>
<input type=button value=\"No, I want to cancel.\" onClick=\"location.href='presentation-acl.tcl?presentation_id=$presentation_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, proceed.\">
</p></center>

[wp_footer]
"
