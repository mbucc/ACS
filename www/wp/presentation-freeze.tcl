# /wp/presentation-freeze.tcl
ad_page_contract {
    Freezes the current slide set.

    @param presentation_id id of the presentation to freeze
    
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @cvs-id presentation-freeze.tcl,v 3.0.12.9 2000/09/22 01:39:32 kevin Exp
} {
    presentation_id:naturalnum,notnull
}

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "admin"

db_1row title_select "
select title from wp_presentations where presentation_id = :presentation_id"



doc_return  200 text/html "[wp_header_form "method=post action=presentation-freeze-2" \
           [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
           [list "presentation-top?presentation_id=$presentation_id" "$title"] "Freeze Presentation"]
[export_form_vars presentation_id]

<p>This feature allows you to permanently preserve the current set of slides in your presentation.
It's especially useful before you invite someone to work on your presentation - if he or she
messes things up, you can always revert to a previous version.

<p>You may enter one line which describes the current state of the presentation
(e.g., \"rough draft\" or \"before modifications by Ben Bitdiddler\").

<p><center><b>Description:</b> <input type=text name=description maxlength=100 size=40>

<p><input type=submit value=\"Freeze Presentation\">

</p></center>
[wp_footer]
"

