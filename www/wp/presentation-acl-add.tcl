# $Id: presentation-acl-add.tcl,v 3.0 2000/02/06 03:55:09 ron Exp $
# File:        presentation-acl-add.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Allows an administrator to add a member to an ACL list.
# Inputs:      presentation_id, role

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

ns_return 200 "text/html" "[wp_header_form "action=/user-search.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl.tcl?presentation_id=$presentation_id" "Authorization"] "Add User"]

<input type=hidden name=target value=\"/[ns_quotehtml [join [lreplace [ns_conn urlv] end end "presentation-acl-add-2.tcl"] "/"]]\">
<input type=hidden name=passthrough value=\"presentation_id role\">
[export_form_vars presentation_id role]

<center>

<p><table border=2 cellpadding=10 width=60%><tr><td>
<table cellspacing=0 cellpadding=0>
<tr><td colspan=2>Please enter part of the E-mail address or last name of the user
you wish to give permission to [wp_role_predicate $role $title].<p>If you can't find the person you're looking for,
he or she probably hasn't yet registered on [ad_system_name], but you can <a href=\"invite.tcl?[export_ns_set_vars]\">invite him or her to
[wp_only_if { $role == "read" } "view" "work on"] your presentation</a>.</p>
<hr></td></tr>
<tr><th align=right>Last Name:&nbsp;</th><td><input name=last_name size=30></td></tr>
<tr><th align=right><i>or</i> E-mail:&nbsp;</th><td><input name=email size=30></td></tr>
<tr><td colspan=2 align=center>
<hr>
<input type=submit value=Search>
</td></tr>
</table></td></tr></table></p></center>

[wp_footer]
"
