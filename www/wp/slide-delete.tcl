# $Id: slide-delete.tcl,v 3.0 2000/02/06 03:55:37 ron Exp $
# File:        slide-delete.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Confirms that the user wants to delete the slide.
# Inputs:      slide_id

set_the_usual_form_variables

# everything for an old slide
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

# Get the slide and presentation information to display a confirmation message.
set selection [ns_db 1row $db "
    select s.*, p.title presentation_title
    from wp_slides s, wp_presentations p
    where s.slide_id = [wp_check_numeric $slide_id]
    and s.presentation_id = p.presentation_id
"]
set_variables_after_query
wp_check_authorization $db $presentation_id $user_id "write"

ReturnHeaders
ns_write "
[wp_header_form "" [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
  [list "presentation-top.tcl?presentation_id=$presentation_id" $presentation_title] "Delete a Slide"]

Are you sure that you want to delete this slide?

<ul>
<li>Title:  $title
<li>Contents:  

$preamble

[expr { $bullet_items != "" ? "<ul>\n<li>[join $bullet_items "<li>\n"]\n</ul>" : "</p>" }]

$postamble

$preamble
</ul>

<input type=button value=\"Yes, delete the slide.\" onClick=\"location.href='slide-delete-2.tcl?slide_id=$slide_id'\">
<input type=button value=\"No, I want to go back.\" onClick=\"history.back()\">

</p>
[wp_footer]
"

