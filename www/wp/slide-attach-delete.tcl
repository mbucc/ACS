# /wp/slide-attach-delete.tcl

ad_page_contract {
    Deletes an attachment.

    @param slide_id the slide from which to delete the attachment
    @param attach_id id of the attachment to delete

    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id slide-attach-delete.tcl,v 3.1.6.5 2000/08/16 21:49:43 mbryzek Exp
} {
    slide_id:naturalnum,notnull
    attach_id:naturalnum,notnull
}

set user_id [ad_maybe_redirect_for_registration]

db_1row wp_pres_id_select "
select presentation_id from wp_slides where slide_id = :slide_id"

wp_check_authorization $presentation_id $user_id "write"

db_dml wp_del_attachment "delete from wp_attachments where attach_id = :attach_id and slide_id = :slide_id"

db_release_unused_handles

ad_returnredirect "slide-attach.tcl?slide_id=$slide_id"
