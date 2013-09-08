# /www/wp/presentation-acl-delete.tcl

ad_page_contract {
    Deletes a user's ACL entry (after confirming).
    
    @author Jon Salz <jsalz@mit.edu>
    @creation-date 28 Nov 1999

    @param presentation_id the ID of the presentation
    @param user_id 

    @cvs-id presentation-acl-delete.tcl,v 3.0.12.9 2000/09/22 01:39:31 kevin Exp
} {
    presentation_id:naturalnum,notnull
    user_id:naturalnum,notnull
}

set req_user_id $user_id

set user_id [ad_maybe_redirect_for_registration]

wp_check_authorization $presentation_id $user_id "admin"

db_1row select_presentation "
select presentation_id,
       title,
       public_p
from   wp_presentations 
where presentation_id = :presentation_id" 

if { [catch { set name [db_string user_name "
select first_names || ' ' || last_name from users where user_id = :req_user_id"] } ] } {
    db_release_unused_handles
    ad_return_error "Invalid User ID" "User $req_user_id not found in the database."
}

doc_return  200 text/html "
[wp_header_form "action=presentation-acl-delete-2" \
	[list "" "WimpyPoint"] \
	[list "index?show_user=" "Your Presentations"] \
	[list "presentation-top?presentation_id=$presentation_id" $title] \
	[list "presentation-acl?presentation_id=$presentation_id" "Authorization"] \
	"Confirm Delete User"]

[export_form_vars presentation_id req_user_id]

<p>Are you sure you want to strip $name's access to $title?
[wp_only_if { $public_p == "t" } "The presentation is public, so the user will still be able to view it."]

<p>

<center>
<input type=button value=\"No, I want to cancel.\" onClick=\"location.href='presentation-acl?presentation_id=$presentation_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, proceed.\">
</p></center>

[wp_footer]
"
