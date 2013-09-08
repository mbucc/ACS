# /wp/slide-delete.tcl

ad_page_contract {
    Confirms that the user wants to delete the slide.    

    @author Jon Salz <jsalz@mit.edu>
    @creation-date 28 Nov 1999

    @param slide_id the ID of the slide

    @cvs-id slide-delete.tcl,v 3.0.12.11 2000/09/22 01:39:36 kevin Exp
} {
    slide_id:naturalnum,notnull
}

# everything for an old slide

set user_id [ad_maybe_redirect_for_registration]

# Get the slide and presentation information to display a confirmation message.
if { [string compare [db_0or1row presentation_select "
select slide_id,
	   p.presentation_id,
	   s.title,
	   preamble,
	   bullet_items,
	   postamble,
           p.title presentation_title
from wp_slides s, wp_presentations p
where s.slide_id = :slide_id
and s.presentation_id = p.presentation_id"] "0"] == 0 } {
    db_release_unused_handles
    ad_return_error "Input error" "Couldn't find slide ID $slide_id in the databse."
}

wp_check_authorization $presentation_id $user_id "write"

set page_content "
[wp_header_form "" [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
  [list "presentation-top?presentation_id=$presentation_id" $presentation_title] "Delete a Slide"]

Are you sure that you want to delete this slide?

<ul>
<li>Title:  $title
<li>Contents:  

$preamble

[expr { $bullet_items != "" ? "<ul>\n<li>[join $bullet_items "<li>\n"]\n</ul>" : "</p>" }]

$postamble

$preamble
</ul>

<input type=button value=\"Yes, delete the slide.\" onClick=\"location.href='slide-delete-2?slide_id=$slide_id'\">
<input type=button value=\"No, I want to go back.\" onClick=\"history.back()\">

</p>
[wp_footer]
"



doc_return  200 "text/html" $page_content
