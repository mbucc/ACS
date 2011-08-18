# $Id: bulk-copy-2.tcl,v 3.0 2000/02/06 03:54:48 ron Exp $
# File:        bulk-copy-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Prompts the user to select slides from a presentation to use for bulk copy.
# Inputs:      presentation_id (the destination presentation)
#              source_presentation_id

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "write"
wp_check_authorization $db $source_presentation_id $user_id "read"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

set source_title [database_to_tcl_string $db "select title from wp_presentations where presentation_id = $source_presentation_id"]

ReturnHeaders
ns_write "[wp_header_form "action=bulk-copy-3.tcl" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           [list "presentation-top.tcl?presentation_id=$presentation_id" "$title"] "Bulk Copy"]

[export_form_vars presentation_id source_presentation_id]

Which slides would you like to copy from $source_title into $title? The new slides
will be added at the end of $title (you can always adjust the order later).
<p>

<center>
<table border=2 cellpadding=10>
<tr><td><table cellspacing=0 cellpadding=0>
"

set out ""
wp_select $db "
    select slide_id, title
    from   wp_slides
    where  presentation_id = $source_presentation_id
    and    max_checkpoint is null
    order by sort_key
" {
    append out "<tr><td><input type=checkbox name=slide_id value=$slide_id>&nbsp;&nbsp;</td><td><a href=\"[wp_presentation_url]/$presentation_id/$slide_id.wimpy\" target=_blank>$title</a></td></tr>\n"
} else {
    append out "<tr><td colspan=2>There are no slides to copy.</td></tr>"
}

ns_write "$out
<tr><td colspan=2 align=center><hr><input type=submit value=\"Insert Checked Slides\"></td></tr>
</table>
</td></tr></table>

</center>
<p>
[wp_footer]
"

