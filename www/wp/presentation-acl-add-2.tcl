# /www/wp/presentation-acl-add-2.tcl

ad_page_contract {
    Adds a user to an ACL (after confirming).
    @creation-date 28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    
    @param passthrough holds variables { presentation_id, role } because this is accessed through user-search.tcl
    @param role type of permission being granted (read, write, admin)
    @param user_id_from_search user id we are searching to add role
    @param first_names_from_search first name of user
    @param last_name_from_search last name of user

    @cvs-id presentation-acl-add-2.tcl,v 3.1.6.8 2000/09/22 01:39:31 kevin Exp
} {
    passthrough_array:array,notnull
    user_id_from_search:naturalnum,notnull
    first_names_from_search:notnull
    last_name_from_search:notnull
}
# modified by psc@arsdigita.com for ACS 3.4 upgrades

set presentation_id $passthrough_array(1)
set role $passthrough_array(2)

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_1row title_select "select title 
from wp_presentations where presentation_id = :presentation_id" 

# Don't let the administrator add an equivalent or lower access level than was previously there.
if { [wp_access $presentation_id $user_id_from_search $role] != "" } {
    db_release_unused_handles
    ad_return_error "User Already Had That Privilege" "
That user can already [wp_role_predicate $role]. Maybe you want to
<a href=\"presentation-acl?presentation_id=$presentation_id\">try again</a>.
"
return
}


doc_return  200 "text/html" "[wp_header_form "action=presentation-acl-add-3" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl?presentation_id=$presentation_id" "Authorization"] "Confirm Add User"]

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
<input type=button value=\"No, I want to cancel.\" onClick=\"location.href='presentation-acl?presentation_id=$presentation_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, proceed.\">
</p></center>

[wp_footer]
"
