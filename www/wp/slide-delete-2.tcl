# /www/wp/slide-delete-2.tcl

ad_page_contract {
    Deletes a slide. 

    @param slide_id is the ID of the slide to delete

    @author Jon Salz <jsalz@mit.edu>
    @creation-date 28 Nov 1999
    @cvs-id slide-delete-2.tcl,v 3.1.6.8 2000/08/16 21:49:43 mbryzek Exp

} {
    slide_id:naturalnum,notnull
}
 
# everything for an old slide

set user_id [ad_maybe_redirect_for_registration]

if { [string compare [db_0or1row pres_id_select "select presentation_id from wp_slides where slide_id = :slide_id"] "0" ] == 0 } { 
    db_release_unused_handles
    ad_return_error "Input error" "Couldn't determine your presentation id from slide id: $slide_id."
}

wp_check_authorization $presentation_id $user_id "write"

db_transaction {

# Remove it from the current view by setting its checkpoint value.
db_dml slide_checkpoint_update "
    update wp_slides
    set    max_checkpoint = (select max(checkpoint) from wp_checkpoints where presentation_id = :presentation_id)
    where  slide_id = :slide_id
    and    max_checkpoint is null
"

# If it's not remaining in any view, just delete it.
db_dml slide_delete "
    delete from wp_slides
    where  slide_id = :slide_id
    and    max_checkpoint = min_checkpoint
"
} on_error {
    ad_return_error "Error" "Couldn't delete slide $slide_id from the database."
}

db_release_unused_handles
ad_returnredirect "presentation-top?presentation_id=$presentation_id"
