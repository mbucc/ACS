# /wp/invite.tcl
ad_page_contract {
    Allows an administrator to invite someone to read/write/admin a presentation.
    @cvs-id invite.tcl,v 3.1.10.9 2000/09/22 01:39:30 kevin Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param presentation_id is the ID of the presentation
    @param role is the role of the user
} {
    presentation_id:naturalnum,notnull
    role:notnull
}
# modified by jwong@arsdigita.com on 10 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_1row title_select "
select title from wp_presentations where presentation_id = :presentation_id" 

db_release_unused_handles

set page_output "[wp_header_form "action=invite-2 method=post" \
	[list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
	[list "presentation-top?presentation_id=$presentation_id" "$title"] \
	[list "presentation-acl?presentation_id=$presentation_id" "Authorization"] "Invite User"]

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

doc_return  200 "text/html" $page_output
