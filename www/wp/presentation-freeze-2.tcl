# /wp/presentation-freeze-2.tcl
ad_page_contract {
    Freezes the current slide set.

    @param presentation_id id of the presentation to freeze
    @param description description of the presentation to freeze

    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs_id presentation-freeze-2.tcl,v 3.1.6.7 2000/08/16 21:49:41 mbryzek Exp
} {
    presentation_id:naturalnum,notnull
    description:notnull
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_1row wp_sel_presentation_info "select presentation_id from wp_presentations where presentation_id = :presentation_id" 

# Do it all in PL/SQL.
db_dml wp_set_ck_pt "begin wp_set_checkpoint(:presentation_id, :description); end;" 

db_release_unused_handles

ad_returnredirect "presentation-top?presentation_id=$presentation_id"
