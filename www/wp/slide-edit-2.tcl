# $Id: slide-edit-2.tcl,v 3.1.2.2 2000/04/28 15:11:42 carsten Exp $
# File:        slide-edit-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Creates or saves changes to a slide.
# Inputs:      presentation_id, slide_id, sort_key, title, preamble, bullet_count bullet1..$bullet_count, postamble, attach

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
if { ![info exists creating] } {
    wp_check_numeric $slide_id
    set presentation_id [database_to_tcl_string $db "select presentation_id from wp_slides where slide_id = $slide_id"]
    set original_slide_id [database_to_tcl_string $db "select nvl(original_slide_id, slide_id) from wp_slides where slide_id = $slide_id"]
} else {
    set condition ""
    set original_slide_id "null"
}
wp_check_authorization $db $presentation_id $user_id "write"

# Turn those individual bullets into a list. Limit to 1000 bullets (to
# prevent some absurd DoS attack)
set bullet_items [list]
for { set i 1 } { $i <= $bullet_count && $i <= 1000 } { incr i } {
    if { [set "bullet$i"] != "" } {
	lappend bullet_items [set "bullet$i"]
    }
}

# Look for problems with user input.
set exception_count 0
set exception_text ""

if { ![info exists title] || $title == "" } {
    append exception_text "<li>Your title was blank.  We need a title to generate the user interface."
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ns_db dml $db "begin transaction"

# Has a checkpoint been set since the last update, i.e.,
# min_checkpoint is not the latest checkpoint and max_checkpoint is null?
if { [info exists slide_id] && [database_to_tcl_string $db "
    select count(*) from wp_slides
    where slide_id = $slide_id
    and min_checkpoint < (select max(checkpoint) from wp_checkpoints where presentation_id = $presentation_id)
    and max_checkpoint is null
"] != 0 } {
    # Yes - need to "close off" that slide. Set its max_checkpoint to the current checkpoint,
    # and start a new slide.
    ns_db dml $db "
        update wp_slides
        set max_checkpoint = (select max(checkpoint) from wp_checkpoints where presentation_id = $presentation_id)
        where slide_id = $slide_id
    "

    set old_slide_id $slide_id
    set slide_id [wp_nextval $db "wp_ids"]
    set creating 1
}

if { ![info exists creating] } {
    set condition "slide_id = $slide_id"
} else {
    set condition ""
    if { [database_to_tcl_string $db "select count(*) from wp_slides where slide_id = $slide_id"] } {
	ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id&new_slide_id=$slide_id"
	return
    }
}

# We're OK... do the insert.

set names [list slide_id presentation_id modification_date sort_key min_checkpoint \
                title preamble bullet_items postamble original_slide_id]
set values [list $slide_id [wp_check_numeric $presentation_id] "sysdate" [wp_check_numeric $sort_key] \
    "(select max(checkpoint) from wp_checkpoints where presentation_id = $presentation_id)" \
    "'$QQtitle'" "empty_clob()" "empty_clob()" "empty_clob()" $original_slide_id]

# Increase the sort key of all slides to come after this one, to "make room"
# in the sorting order.
ns_db dml $db "
    update wp_slides
    set sort_key = sort_key + 1
    where presentation_id = $presentation_id
    and sort_key >= $sort_key
    and max_checkpoint is null
"

wp_try_dml_or_break $db [wp_prepare_dml "wp_slides" $names $values $condition] \
    [list [list "preamble" $preamble] [list "bullet_items" $bullet_items] [list "postamble" $postamble]]

if { [info exists old_slide_id] } {
    # Copy attachments over to the new version of the slide.
    ns_db dml $db "
        insert into wp_attachments(attach_id, slide_id, attachment, file_size, file_name, mime_type, display)
            select wp_ids.nextval, $slide_id, attachment, file_size, file_name, mime_type, display
            from   wp_attachments
            where  slide_id = $old_slide_id
    "
}

ns_db dml $db "end transaction"

if { [info exists attach] } {
    ad_returnredirect "slide-attach.tcl?slide_id=$slide_id"
} else {
    ad_returnredirect "presentation-top.tcl?presentation_id=$presentation_id&new_slide_id=$slide_id"
}
