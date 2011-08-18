# $Id: bulk-copy-3.tcl,v 3.0.4.1 2000/03/18 01:10:53 jsalz Exp $
# File:        bulk-copy-3.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Performs a bulk copy of slides.
# Inputs:      presentation_id (target), source_presentation_id
#              slide_id (multiple values)

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "write"
wp_check_authorization $db $source_presentation_id $user_id "read"

set slide_id_list [util_GetCheckboxValues [ns_getform] slide_id]

if { ![info exists slide_id] || $slide_id_list == 0 } {
    ad_return_complaint 1 [list "Please check at least one slide."]
    return
}

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

ReturnHeaders
ns_write "[wp_header_form "action=bulk-copy-3.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] \
           [list "bulk-copy.tcl?presentation_id=$presentation_id" "Bulk Copy"] "Copying Slides"]

<ul>
"

wp_check_numeric $presentation_id
wp_check_numeric $source_presentation_id

set sort_key [expr [database_to_tcl_string $db "select max(sort_key) from wp_slides where presentation_id = $presentation_id"] + 1.0]

ns_db dml $db "begin transaction"
foreach slide_id $slide_id_list {
    # Do one at a time so we can display <li>s to indicate progress.
    set next_id [wp_nextval $db "wp_ids"]

    ns_write "<li>[database_to_tcl_string $db "select title from wp_slides where presentation_id = $source_presentation_id and slide_id = $slide_id"]...</li>\n"
    ns_db dml $db "
        insert into wp_slides(slide_id, presentation_id, min_checkpoint, sort_key, title,
                              preamble, bullet_items, postamble, modification_date, style)
        select $next_id, $presentation_id, (select max(checkpoint) from wp_checkpoints where presentation_id = $presentation_id), $sort_key, title,
               preamble, bullet_items, postamble,
               sysdate, style
        from   wp_slides
        where  presentation_id = $source_presentation_id
        and    slide_id = [wp_check_numeric $slide_id]
    "
    ns_db dml $db "
        insert into wp_attachments(attach_id, slide_id, attachment, file_size, file_name, mime_type, display)
        select wp_ids.nextval, $next_id, attachment, file_size, file_name, mime_type, display
        from   wp_attachments
        where  slide_id = [wp_check_numeric $slide_id]
    "
    set sort_key [expr { $sort_key + 1.0 }]
}

ns_db dml $db "end transaction"

ns_write "<li>Finished.

<p><a href=\"presentation-top.tcl?presentation_id=$presentation_id\">Return to $title</a>

</ul>
[wp_footer]
"
