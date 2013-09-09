# /wp/presentation-revert-2.tcl

ad_page_contract {
    Reverts a presentation to a previous version.

    @param presentation_id id of the prsentation to revert
    @param checkpoint checkpoint to which to revert

    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id presentation-revert-2.tcl,v 3.1.6.5 2000/08/16 21:49:42 mbryzek Exp
} {
    presentation_id:naturalnum,notnull
    checkpoint:naturalnum,notnull
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_dml wp_pres_revert "begin wp_revert_to_checkpoint(:presentation_id, :checkpoint); end;"

db_release_unused_handles

ad_returnredirect "presentation-top?presentation_id=$presentation_id"
