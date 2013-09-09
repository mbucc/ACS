# /wp/presentation-public.tcl
ad_page_contract {
    Makes a presentation (non-)public.
    
    @param presentation_id the presentation to make (non-)public
    @param public_p make this presentation public?

    @creation-date   28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id presentation-public.tcl,v 3.1.6.5 2000/08/16 21:49:42 mbryzek Exp
} {
    presentation_id:naturalnum,notnull
    public_p:notnull
}
    
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_dml wp_public_p_update "update wp_presentations 
set public_p=:public_p 
where presentation_id = :presentation_id"

db_release_unused_handles

ad_returnredirect "presentation-acl.tcl?presentation_id=$presentation_id"
