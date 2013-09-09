# /wp/uninvite-2.tcl
ad_page_contract {
    Deletes a wp_user_access_ticket.
    @cvs-id uninvite-2.tcl,v 3.1.6.9 2000/08/16 21:49:45 mbryzek Exp
    @creation-date  28 Nov 1999
    @author  Jon Salz <jsalz@mit.edu>
    @param presentation_id is the ID of the presentation
    @param invitation_id is the ID of the invitation to delete
} {
    presentation_id:naturalnum,notnull
    invitation_id:naturalnum,notnull
}
# modified by jwong@arsdigita.com on 10 Jul 2000 for ACS 3.4

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_1row invitation_select "select presentation_id from wp_presentations where presentation_id = :presentation_id" 

db_dml invitation_delete "delete from wp_user_access_ticket where presentation_id = :presentation_id and invitation_id = :invitation_id" 

db_release_unused_handles

ad_returnredirect "presentation-acl?presentation_id=$presentation_id"
