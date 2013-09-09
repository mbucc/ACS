# /wp/bulk-copy-3.tcl
ad_page_contract {
    Performs a bulk copy of slides.
    @cvs-id bulk-copy-3.tcl,v 3.2.6.13 2000/09/22 01:39:29 kevin Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param presentation_id (target)
    @param source_presentation_id
    @param slide_id (multiple values)
} {
    presentation_id:naturalnum,notnull
    source_presentation_id:naturalnum,notnull
    slide_id:multiple,naturalnum,notnull
} -errors {
    slide_id {Please check at least one slide.}
}

# modified by jwong@arsdigita.com on 11 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "write"
wp_check_authorization $source_presentation_id $user_id "read"

db_1row title_select "select title from wp_presentations where presentation_id = :presentation_id" 

set page_output "[wp_header_form "action=bulk-copy-3.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] \
           [list "bulk-copy.tcl?presentation_id=$presentation_id" "Bulk Copy"] "Copying Slides"]

<ul>
"

wp_check_numeric $presentation_id
wp_check_numeric $source_presentation_id

set sort_key [expr [db_string sort_key_select {
    select max(sort_key) 
      from wp_slides 
     where presentation_id = :presentation_id
}] + 1.0]

db_transaction {
    foreach slide $slide_id {
        # Do one at a time so we can display <li>s to indicate progress.
        set next_id [db_nextval "wp_ids"]
        
        append page_output "<li>[db_string title_select {
            select title 
              from wp_slides where presentation_id = :source_presentation_id 
               and slide_id = :slide
        }]...</li>\n"

        db_dml slide_insert {
            insert into wp_slides 
            (slide_id, presentation_id, min_checkpoint, sort_key, title,
             preamble, bullet_items, postamble, modification_date, style)
            select :next_id, 
                   :presentation_id, 
                   (select max(checkpoint) 
                      from wp_checkpoints 
                     where presentation_id = :presentation_id), 
                   :sort_key, 
                   title,
                   preamble, 
                   bullet_items, 
                   postamble,
                   sysdate, 
                   style
              from wp_slides
             where presentation_id = :source_presentation_id
               and slide_id = :slide
        }
        db_dml attachment_insert {
            insert into wp_attachments(attach_id, slide_id, attachment, file_size, file_name, mime_type, display)
            select wp_ids.nextval, :next_id, attachment, file_size, file_name, mime_type, display
              from wp_attachments
             where slide_id = :slide
        } 
        set sort_key [expr { $sort_key + 1.0 }]
    }
}

db_release_unused_handles

append page_output "<li>Finished.
<p><a href=\"presentation-top?presentation_id=$presentation_id\">Return to $title</a>
</ul>
[wp_footer]
"

doc_return  200 "text/html" $page_output
