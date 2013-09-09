# /wp/outline-adjust.tcl
ad_page_contract {
    Allows the user to adjust outline/context-break information.
    @cvs-id outline-adjust.tcl,v 3.0.12.8 2000/09/22 01:39:31 kevin Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param presentation_id is the ID of the presentation to adjust
} {
    presentation_id:naturalnum,notnull
}
# modified by jwong@arsdigita.com on 11 Jul 2000 for ACS 3.4 upgrade

set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $presentation_id $user_id "write"

db_1row title_select "select title from wp_presentations where presentation_id = :presentation_id" 

set page_output "[wp_header_form "action=outline-adjust-2.tcl" \
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
set slides [db_list_of_lists slide_select "
    select slide_id, title, include_in_outline_p, context_break_after_p
    from wp_slides 
    where presentation_id = :presentation_id
    and max_checkpoint is null
    order by sort_key
" ]

db_release_unused_handles

set list_length [llength $slides]
set i 0
foreach slide $slides {
    incr i
    set slide_id [lindex $slide 0]
    set title [lindex $slide 1]
    set include_in_outline_p [lindex $slide 2]
    set context_break_after_p [lindex $slide 3]
    # append context break option if not the last slide
    append out "<tr>
<td>$title</td>
<td></td>
<td align=center><input type=checkbox name=include_in_outline value=$slide_id [wp_only_if { $include_in_outline_p == "t" } "checked"]></td>
<td></td>
[wp_only_if { $i < $list_length } "<td align=center><input type=checkbox name=context_break_after value=$slide_id [wp_only_if { $context_break_after_p == "t" } "checked"]></td>"]
</tr>
"
}

append page_output "$out
<tr><td colspan=5 align=center><hr><input type=submit value=\"Save Changes\"></td></tr>
</table>
</td></tr></table>
<p>

</center>
[wp_footer]
"

doc_return  200 "text/html" $page_output