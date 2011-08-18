# $Id: presentation-revert.tcl,v 3.0 2000/02/06 03:55:25 ron Exp $
# File:        presentation-revert.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Reverts a presentation to a previous version, after confirming.
# Inputs:      presentation_id, checkpoint

set_the_usual_form_variables

set db [ns_db gethandle]

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

set selection [ns_db 1row $db "
    select description, TO_CHAR(checkpoint_date, 'Month DD, YYYY, HH:MI A.M.') checkpoint_date
    from wp_checkpoints
    where checkpoint = [wp_check_numeric $checkpoint]
    and presentation_id = $presentation_id
"]
set_variables_after_query

ReturnHeaders
ns_write "[wp_header_form "action=presentation-revert-2.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] "Revert Presentation"]
[export_form_vars presentation_id checkpoint]

<p>Do you really want to revert $title to the version entitled &quot;$description,&quot; made
at $checkpoint_date? You will permanently lose any change made to your presentation since then.

<p><center>
<input type=button value=\"No, I want to cancel.\" onClick=\"location.href='presentation-top.tcl?presentation_id=$presentation_id'\">
<spacer type=horizontal size=50>
<input type=submit value=\"Yes, proceed.\">
</p></center>

[wp_footer]
"

