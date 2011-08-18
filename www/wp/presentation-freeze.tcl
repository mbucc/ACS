# $Id: presentation-freeze.tcl,v 3.0 2000/02/06 03:55:21 ron Exp $
# File:        presentation-freeze.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Freezes the current slide set.
# Inputs:      presentation_id

set_the_usual_form_variables

set db [ns_db gethandle]

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

ReturnHeaders
ns_write "[wp_header_form "method=post action=presentation-freeze-2.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] "Freeze Presentation"]
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

