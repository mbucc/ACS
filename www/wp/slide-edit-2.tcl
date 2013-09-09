# /wp/slide-edit-2.tcl

ad_page_contract {
    Creates or saves changes to a slide.
    @cvs-id slide-edit-2.tcl,v 3.3.6.17 2001/01/12 00:48:01 khy Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param presentation_id
    @param slide_id
    @param sort_key
    @param title
    @param bullet_count
    @param bullet.$i
} {
    presentation_id:naturalnum,notnull
    slide_id:naturalnum,optional,verify
    sort_key:notnull
    title:allhtml,notnull
    {preamble:allhtml,optional ""}
    bullet_count:naturalnum,notnull
    bullet:allhtml,array,optional
    {postamble:allhtml,optional ""}
    attach:optional
    creating:optional
} -errors {
    title:notnull { Title must not be empty. }
}
# modified by jwong@arsdigita.com on 11 Jul 2000 for ACS 3.4

set user_id [ad_maybe_redirect_for_registration]
if { ![info exists creating] } {
    set presentation_id [db_string select_presentation_id "select presentation_id from wp_slides where slide_id = :slide_id"]
    set original_slide_id [db_string select_original_slide_id "select nvl(original_slide_id, slide_id) from wp_slides where slide_id = :slide_id"]
} else {
    set condition ""
    # need to use "null" instead of db_null for wp_prepare_dml, o/w leaves an empty value
    set original_slide_id "null"
}

wp_check_authorization $presentation_id $user_id "write"

# Turn those individual bullets into a list. Limit to 1000 bullets (to
# prevent some absurd DoS attack)
set bullet_items [list]
for { set i 1 } { $i <= $bullet_count && $i <= 1000 } { incr i } {
    if { [set "bullet($i)"] != "" } {
	lappend bullet_items [set "bullet($i)"]
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

db_transaction {

# Has a checkpoint been set since the last update, i.e.,
# min_checkpoint is not the latest checkpoint and max_checkpoint is null?
if { [info exists slide_id] && [db_string count_slides "
    select count(*) from wp_slides
    where slide_id = :slide_id
    and min_checkpoint < (select max(checkpoint) from wp_checkpoints where presentation_id = $presentation_id)
    and max_checkpoint is null
"] != 0 } {
    # Yes - need to "close off" that slide. Set its max_checkpoint to the current checkpoint,
    # and start a new slide.
    db_dml update_slides "
        update wp_slides
        set max_checkpoint = (select max(checkpoint) from wp_checkpoints where presentation_id = :presentation_id)
        where slide_id = :slide_id
    "

    set old_slide_id $slide_id
    set slide_id [wp_nextval "wp_ids"]
    set creating 1
}

if { ![info exists creating] } {
    set condition "slide_id = [wp_check_numeric $slide_id]"
} else {
    set condition ""
    if { [db_string count_slides_2 "select count(*) from wp_slides where slide_id = :slide_id"] } {
	ad_returnredirect "presentation-top?presentation_id=$presentation_id&new_slide_id=$slide_id"
	return
    }
}

# We're OK... do the insert.

set max_checkpoint [db_string max_checkpoint \
	"select max(checkpoint) from wp_checkpoints where presentation_id = :presentation_id"]

set names [list slide_id presentation_id modification_date sort_key min_checkpoint \
                title preamble bullet_items postamble original_slide_id]
set values [list $slide_id $presentation_id "sysdate" $sort_key $max_checkpoint \
    $title "empty_clob()" "empty_clob()" "empty_clob()" $original_slide_id]

# Increase the sort key of all slides to come after this one, to "make room"
# in the sorting order.
db_dml update_slides_2 "
    update wp_slides
    set sort_key = sort_key + 1
    where presentation_id = :presentation_id
    and sort_key >= :sort_key
    and max_checkpoint is null
"

wp_try_dml_or_break [wp_prepare_dml "wp_slides" $names $values $condition] \
    [list [list "preamble" $preamble] [list "bullet_items" $bullet_items] [list "postamble" $postamble]]

if { [info exists old_slide_id] } {
    # Copy attachments over to the new version of the slide.
    db_dml insert_wp_attachments "
        insert into wp_attachments(attach_id, slide_id, attachment, file_size, file_name, mime_type, display)
            select wp_ids.nextval, $slide_id, attachment, file_size, file_name, mime_type, display
            from   wp_attachments
            where  slide_id = :old_slide_id
    "
}

}

db_release_unused_handles

if { [info exists attach] } {
    ad_returnredirect "slide-attach?slide_id=$slide_id"
} else {
    ad_returnredirect "presentation-top?presentation_id=$presentation_id&new_slide_id=$slide_id"
}




