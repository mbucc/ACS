# $Id: presentation-edit.tcl,v 3.0 2000/02/06 03:55:18 ron Exp $
# File:        presentation-edit.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Allows the user to create or edit a presentation.
# Inputs:      presentation_id (if editing)

set_the_usual_form_variables 0
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

if { [info exists presentation_id] } {
    # Editing an existing presentation - check auth and grab info from the database.
    wp_check_authorization $db $presentation_id $user_id "write"
    set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
    set_variables_after_query

    set header [list "presentation-top.tcl?presentation_id=$presentation_id" $title]

    set role "Edit"

    # Give the user access to any style owned by any other collaborator.
    set or_styles "or owner in (select user_id from user_group_map
                                      where group_id = $group_id
                                      and   role in ('write','admin'))"
    if { $style != "" } {
	# Make sure the user has access to the currently set style.
	append or_styles " or style_id = $style"
    }
} else {
    # Creating a new presentation - set some defaults.
    foreach var { title description page_signature copyright_notice audience background } {
	set $var ""
    }
    set show_modified_p "f"
    set public_p "t"
    set style -1

    set header ""

    set role "Create"

    set or_styles ""

    set presentation_id [wp_nextval $db "wp_ids"]
    set creating "t"
}

# Generate the list of styles. If the owner is the current user or null, or the
# style is public, the user can see it.
set styles ""
wp_select $db "
    select style_id, name
    from   wp_styles
    where  owner = $user_id
    or     owner is null
    or     public_p = 't'
    $or_styles
" {
    append styles "<option value=$style_id"
    if { $style == $style_id } {
	append styles " selected"
    }
    append styles ">$name\n"
}

ReturnHeaders
ns_write "[wp_header_form "name=f action=presentation-edit-2.tcl method=post" \
           [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
           $header "$role Presentation"]
[export_form_vars presentation_id creating]

<table>
  <tr>
    <td></td><td>
Give this presentation a title.  Pick a title that you've never used
before, otherwise you won't be able to tell this new presentation from 
old ones.  Also, keep the title reasonably short so that if you choose
a style where the overall presentation title is presented on each slide,
it won't take up too much space.
    </td>
  </tr>
  <tr>
    <th nowrap align=right>Title:</th>
    <td><input type=text name=title size=50 value=\"[philg_quote_double_quotes $title]\"></td>
  </tr>
  <tr>
    <td></td><td>
If you want a signature at the bottom of each slide, then enter it here:
    </td>
  </tr>
  <tr>
    <th nowrap align=right>Page Signature:</th>
    <td><input type=text name=page_signature size=50 value=\"[philg_quote_double_quotes $page_signature]\"></td>
  </tr>
  <tr>
    <td></td><td>
(Personally, I like to have my email address, hyperlinked to my home
page; remember that HTML is OK here and you can have up to 200 characters.)

<p>If you want a copyright notice somewhere on each slide, enter it here:
    </td>
  </tr>
  <tr>
    <th nowrap align=right>Copyright Notice:</th>
    <td><input type=text name=copyright_notice size=50 value=\"[philg_quote_double_quotes $copyright_notice]\"></td>
  </tr>
  <tr>
    <td></td><td>
WimpyPoint keeps track of the last modification time
of each slide.  If you'd like that displayed on each slide, you can
say so here:
    </td>
  </tr>
  <tr>
    <th nowrap align=right>Show Modification Date?</th>
    <td>
<input type=radio name=show_modified_p value=t [wp_only_if { $show_modified_p == "t" } "checked"]> Yes
<input type=radio name=show_modified_p value=f [wp_only_if { $show_modified_p == "f" } "checked"]> No
    </td>
  </tr>
  <tr>
    <td></td><td>
If you want to hide this presentation from everyone except yourself
and any collaborators that you add, you should say so.  Eventually
you'll probably want to change this and make the presentation public,
unless you are only using WimpyPoint to generate .html
pages and/or hardcopy slides that you will show privately.
    </td>
  </tr>
  <tr>
    <th nowrap align=right>Available to Public?</th>
    <td>
<input type=radio name=public_p value=t [wp_only_if { $public_p == "t" } "checked"]> Yes
<input type=radio name=public_p value=f [wp_only_if { $public_p == "f" } "checked"]> No
    </td>
  </tr>
  <tr>
    <td></td><td>
Suggestion: if you have truly secret information for a presentation,
you'd be best off keeping it on your desktop machine.  We try to keep
our database secure but remember that your packets are being sent in
the clear.

<p>Want to make your presentation pretty? Select a style to give your presentation
some pizzazz. If you select \"I'll provide my own,\" once you submit this form
you'll be given the opportunity to create a style, selecting your own color
scheme, background image, etc.
(You can access your personal style repository by clicking the link
entitled <i>Edit one of your styles</i> from WimpyPoint's main page.)
    </td>
  </tr>
  <tr>
    <th nowrap align=right>Style:</th>
    <td><select name=style>
$styles
<option value=\"upload\">I'll provide my own
</select>
    </td>
  </tr>
  <tr>
    <td></td><td>
<p>Finally, if you're planning on making the presentation public, you might want to let the
world know whom you gave the presentation to and for what purpose.
    </td>
  </tr>
  <tr valign=top>
    <th nowrap align=right><br>Audience:</th>
    <td><textarea name=audience rows=4 cols=50 wrap=virtual>[philg_quote_double_quotes $audience]</textarea></td>
  </tr>
  <tr valign=top>
    <th nowrap align=right><br>Background:</th>
    <td><textarea name=background rows=4 cols=50 wrap=virtual>[philg_quote_double_quotes $audience]</textarea></td>
  </tr>
</table>

<center>
<input type=submit value=\"Save Presentation\">
</center>
</p>

[wp_footer]
"