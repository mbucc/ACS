# $Id: style-list.tcl,v 3.0 2000/02/06 03:55:48 ron Exp $
# File:        style-list.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Shows all styles.
# Inputs:      None.

set_the_usual_form_variables 0
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

ReturnHeaders
ns_write "[wp_header_form "name=f action=style-image-add.tcl method=post enctype=multipart/form-data" \
           [list "" "WimpyPoint"] "Your Styles"]

<p><center>

<table border=2 cellpadding=10><tr><td>
<table cellspacing=0 cellpadding=0>
<tr>
<th align=left>Style</th><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
<th align=right>#&nbsp;Images</th><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
<th align=right>Total Size</th><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
</tr>
<tr><td colspan=7><hr></td></tr>
"

set db2 [ns_db gethandle subquery]

set out ""
wp_select $db "
    select s.style_id, s.name, count(file_size) images, sum(file_size) total_size
    from wp_styles s, wp_style_images i
    where s.style_id = i.style_id(+)
    and s.owner = $user_id
    group by s.style_id, s.name
    order by lower(s.name)
" {
    append out "<tr><td><a href=\"style-view.tcl?style_id=$style_id\">$name</a></td><td></td>
<td align=right>$images</td><td></td>
"
    if { $total_size != "" } {
        append out "<td align=right>[format "%.1f" [expr $total_size / 1024.0]]K</td>"
    } else {
	append out "<td align=right>-</td>"
    }
    append out "<td></td><td>\[ <a href=\"style-delete.tcl?style_id=$style_id\">delete</a> \]</td></tr>\n"
} else {
    append out "<tr><td align=center colspan=7><i>You haven't created any styles.</i></td></tr>"
}

ns_db releasehandle $db2

ns_write "$out

<tr><td colspan=7 align=center><hr><b><a href=\"style-edit.tcl\">Create a new style</a></b></td></tr>

</table>
</td></tr></table>

</center></p>

[wp_footer]
"