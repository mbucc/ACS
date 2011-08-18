# $Id: outline-adjust.tcl,v 3.0 2000/02/06 03:55:04 ron Exp $
# File:        outline-adjust.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Allows the user to adjust outline/context-break information.
# Inputs:

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "write"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

ReturnHeaders
ns_write "[wp_header_form "action=outline-adjust-2.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] "Adjust Outline"]

[export_form_vars presentation_id]

If you add a context break after a slide, pressing the next button on
that slide will take you to an outline slide with the key slide
highlighted.  Note that this context break only works for you (and
any collaborators), and not for the general public.
This is on the theory that the public pages are for casual readers
browsing this site when you're not around whereas the private pages
are what you use when you're giving a talk.  Unless you work for the
US Department of Defense, we recommend no more than two or three
context breaks per lecture.

<p>
<center>
<table border=2 cellpadding=10><tr><td>
<table cellspacing=0 cellpadding=0>
<tr valign=bottom>
<th align=left><font size=+1>Slide Title</th>
<td>&nbsp;&nbsp;</td>
<th nowrap>Include<br>in Outline</th>
<td>&nbsp;&nbsp;</td>
<th nowrap>Context Break<br>After</th>
</tr>
<tr><td colspan=5><hr></td></tr>
"

set last_slide_id ""

set out ""
set selection [ns_db select $db "
    select slide_id, title, include_in_outline_p, context_break_after_p
    from wp_slides 
    where presentation_id = $presentation_id
    and max_checkpoint is null
    order by sort_key
"]
set more_rows [ns_db getrow $db $selection]
while { $more_rows } {
    set_variables_after_query
    set more_rows [ns_db getrow $db $selection]

    append out "<tr>
<td>$title</td>
<td></td>
<td align=center><input type=checkbox name=include_in_outline value=$slide_id [wp_only_if { $include_in_outline_p == "t" } "checked"]></td>
<td></td>
[wp_only_if { $more_rows } "<td align=center><input type=checkbox name=context_break_after value=$slide_id [wp_only_if { $context_break_after_p == "t" } "checked"]></td>"]
</tr>
"
}

ns_write "$out
<tr><td colspan=5 align=center><hr><input type=submit value=\"Save Changes\"></td></tr>
</table>
</td></tr></table>
<p>

</center>
[wp_footer]
"