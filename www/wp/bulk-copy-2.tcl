# /wp/bulk-copy-2.tcl
ad_page_contract {
    Prompts the user to select slides from a presentation to use for bulk copy.
    @cvs-id bulk-copy-2.tcl,v 3.1.2.11 2000/09/22 01:39:28 kevin Exp
    @creation-date  28 Nov 1999
    @author  Jon Salz <jsalz@mit.edu>
    @param  presentation_id (the destination presentation)
    @param  source_presentation_id
} {
    presentation_id:naturalnum,notnull
    source_presentation_id:naturalnum,notnull
}
# modified by jwong@arsdigita.com on 11 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "write"
wp_check_authorization $source_presentation_id $user_id "read"

db_1row pres_select "select title from wp_presentations where presentation_id = :presentation_id" 

set source_title [db_string title_select "select title from wp_presentations where presentation_id = :source_presentation_id"]

set page_output "[wp_header_form "action=bulk-copy-3.tcl" \
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
db_foreach slides_from_presentation_select "
    select slide_id, title
    from   wp_slides
    where  presentation_id = :source_presentation_id
    and    max_checkpoint is null
    order by sort_key
" {
    append out "<tr><td><input type=checkbox name=slide_id value=$slide_id>&nbsp;&nbsp;</td><td><a href=\"[wp_presentation_url]/$source_presentation_id/$slide_id.wimpy\" target=_blank>$title</a></td></tr>\n"
} else {
    append out "<tr><td colspan=2>There are no slides to copy.</td></tr>"
}

db_release_unused_handles

append page_output "$out
<tr><td colspan=2 align=center><hr><input type=submit value=\"Insert Checked Slides\"></td></tr>
</table>
</td></tr></table>

</center>
<p>
[wp_footer]
"

doc_return  200 "text/html" $page_output