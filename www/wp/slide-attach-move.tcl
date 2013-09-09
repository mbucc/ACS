# /wp/slide-attach-move.tcl

ad_page_contract {
    Changes the display mode for an attachment.

    @param attach_id the slide whose attachment display we are changing
    @param display the new display mode

    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id slide-attach-move.tcl,v 3.1.6.5 2000/08/16 21:49:43 mbryzek Exp
} {
    attach_id:naturalnum,notnull
    display:notnull
}

set user_id [ad_maybe_redirect_for_registration]

db_1row wp_slide_info_select "
    select s.presentation_id, s.slide_id
    from   wp_slides s, wp_attachments a
    where  a.attach_id = :attach_id
    and    s.slide_id = a.slide_id
"

wp_check_authorization $presentation_id $user_id "write"

db_dml wp_display_update "
    update wp_attachments
    set display = :display
    where attach_id = :attach_id
"

db_release_unused_handles

ad_returnredirect "slide-attach.tcl?slide_id=$slide_id"
