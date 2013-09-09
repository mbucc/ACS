# wp/style-list.tcl
ad_page_contract {
    Shows all styles.
    @param none
    @cvs-id style-list.tcl,v 3.1.6.9 2000/09/22 01:39:37 kevin Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
} {
}
# modified by jwong@arsdigita.com on 11 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]

set page_output "[wp_header_form "name=f action=style-image-add method=post enctype=multipart/form-data" \
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

set out ""

db_foreach styles_select "
    select s.style_id, s.name, count(file_size) images, sum(file_size) total_size
    from wp_styles s, wp_style_images i
    where s.style_id = i.style_id(+)
    and s.owner = :user_id
    group by s.style_id, s.name
    order by lower(s.name)
" {
    append out "<tr><td><a href=\"style-view?style_id=$style_id\">$name</a></td><td></td>
<td align=right>$images</td><td></td>
"
    if { $total_size != "" } {
        append out "<td align=right>[format "%.1f" [expr $total_size / 1024.0]]K</td>"
    } else {
	append out "<td align=right>-</td>"
    }
    append out "<td></td><td>\[ <a href=\"style-delete?style_id=$style_id\">delete</a> \]</td></tr>\n"
} else {
    append out "<tr><td align=center colspan=7><i>You haven't created any styles.</i></td></tr>"
}

db_release_unused_handles

append page_output  "$out

<tr><td colspan=7 align=center><hr><b><a href=\"style-edit\">Create a new style</a></b></td></tr>

</table>
</td></tr></table>

</center></p>

[wp_footer]
"

doc_return  200 "text/html" $page_output