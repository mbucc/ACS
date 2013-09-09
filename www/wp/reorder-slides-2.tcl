# /wp/reorder-slides-2.tcl

ad_page_contract {
    Saves changes made to slide order.

    @param presentation_id
    @param slide_id list of slide_ids in order from reorder-slides

    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id reorder-slides-2.tcl,v 3.1.6.7 2000/08/16 21:49:43 mbryzek Exp
} {
    presentation_id:naturalnum,notnull
    slide_id:multiple,naturalnum,notnull
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "write"

# Just iterate over the values for slide_id in order and set their respective
# sort_keys to 1, 2, 3, ...
set counter 0
foreach slide $slide_id {
    incr counter
    db_dml wp_slide_order_update "
        update wp_slides
        set    sort_key = :counter
        where  slide_id = :slide
        and    presentation_id = :presentation_id
    "
}

db_release_unused_handles

ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id"

