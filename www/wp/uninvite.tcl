# /wp/uninvite.tcl
ad_page_contract {
    Deletes a wp_user_access_ticket (after confirming).
    @cvs-id uninvite.tcl,v 3.0.12.9 2000/09/22 01:39:37 kevin Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param presentation_id is the ID of the presentation
    @param invitation_id is the ID of the invitation to delete
} {
    presentation_id:naturalnum,notnull
    invitation_id:naturalnum,notnull
}
# modified by jwong@arsdigita.com on 10 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

set exception_count 0
set exception_text ""

if { ![db_0or1row pres_id_and_title "
select presentation_id,	title
from wp_presentations 
where presentation_id = :presentation_id" ] } {
    incr exception_count
    append exception_text "<p>Invalid presentation ID."
}

wp_check_numeric $invitation_id

if { ![db_0or1row pres_ticket_select "
    select name, role
    from   wp_user_access_ticket
    where  invitation_id = :invitation_id
    and    presentation_id = :presentation_id
" ] } {
    incr exception_count
    append exception_text "<p>No invitation found."
}

db_release_unused_handles

if { $exception_count } { ad_return_error "Error" $exception_text }

doc_return  200 "text/html" "
[wp_header_form "action=uninvite-2" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] \
           [list "presentation-acl?presentation_id=$presentation_id" "Authorization"] "Confirm Delete User"]

[export_form_vars presentation_id invitation_id]

<p>Are you sure you want to revoke $name's invitation to [wp_role_predicate $role $title]?

<p><center>
<input type=button value=\"No, I want to cancel.\" onClick=\"location.href='presentation-acl?presentation_id=$presentation_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, proceed.\">
</p></center>

[wp_footer]
"
