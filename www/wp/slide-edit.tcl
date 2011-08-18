# $Id: slide-edit.tcl,v 3.1 2000/02/25 16:45:04 jsalz Exp $
# File:        slide-edit.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Allows the user to create or edit a slide.
# Inputs:      presentation_id (if creating)
#              slide_id (to edit) or sort_key (to create)

set_the_usual_form_variables
set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]

if { [info exists slide_id] } {
    # Editing an existing slide.
    set selection [ns_db 1row $db "select * from wp_slides where slide_id = [wp_check_numeric $slide_id]"]
    set_variables_after_query

    set role "Edit"
} else {
    # Creating a new slide.
    foreach var { title preamble bullet_items postamble } {
	set $var ""
    }
    set slide_id [wp_nextval $db "wp_ids"]
    set creating "t"

    set role "Create"
}
wp_check_authorization $db $presentation_id $user_id "write"

# Display n + 3 (but always at least 5) bullet item slots, where n = the number
# of bullet items currently on the slide.
set bullet_count [expr [llength $bullet_items] + 3]
if { $bullet_count < 5 } {
    set bullet_count 5
}
set bullet_items_html "[export_form_vars bullet_count]"
for { set i 0 } { $i < $bullet_count } { incr i } {
    set value [lindex $bullet_items $i]
    append bullet_items_html "<li>"
    if { [string length $value] > 60 } {
	set rows [expr { [string length $value] / 45 }]
	if { $rows < 3 } {
	    set rows 3
	} elseif { $rows > 8 } {
	    set rows 8
	}
	append bullet_items_html "<textarea wrap=soft rows=$rows cols=60 name=bullet[expr $i + 1]>[philg_quote_double_quotes $value]</textarea>"
    } else {
	append bullet_items_html "<input type=text size=60 name=bullet[expr $i + 1] value=\"[philg_quote_double_quotes $value]\">"
    }
    append bullet_items_html "&nbsp;"
    if { $i == 0 } {
	append bullet_items_html "<img src=\"pics/1white.gif\" width=18 height=15\">"
    } else {
	append bullet_items_html "<a href=\"javascript:swapWithNext($i)\"><img src=\"pics/up.gif\" width=18 height=15 border=0></a>"
    }
    if { $i == $bullet_count - 1 } {
	append bullet_items_html "<img src=\"pics/1white.gif\" width=18 height=15\">"
    } else {
	append bullet_items_html "<a href=\"javascript:swapWithNext([expr $i + 1])\"><img src=\"pics/down.gif\" width=18 height=15 border=0></a>"
    }
    append bullet_items_html "\n"
}

ReturnHeaders
ns_write "
[wp_header_form "name=f action=slide-edit-2.tcl method=post" [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] \
  [list "presentation-top.tcl?presentation_id=$presentation_id" [database_to_tcl_string $db "select title from wp_presentations where presentation_id = $presentation_id"]] "$role a Slide"]

[export_form_vars presentation_id slide_id sort_key creating]

<script language=javascript>
function swapWithNext(index)
{
  var val = document.f\['bullet' + index\].value;
  document.f\['bullet' + index\].value = document.f\['bullet' + (index+1)\].value;
  document.f\['bullet' + (index+1)\].value = val;
}
</script>

<table>
  <tr>
    <th align=right nowrap>Slide Title:&nbsp;</th>
    <td><input type=text name=title value=\"[philg_quote_double_quotes $title]\" size=50></td>
  </tr>
  <tr valign=top>
    <th align=right nowrap><br>Preamble:</th>
    <td>
      <textarea rows=6 cols=70 name=preamble wrap=virtual>[philg_quote_double_quotes $preamble]</textarea><br>
      <i>(optional random text that goes above the bullet list)</i>
    </td>
  </tr>
  <tr valign=baseline>
    <th align=right nowrap>Bullet Items:</th>
    <td>
      <ul>
        $bullet_items_html
        <br><i>You can add additional bullets later.</i>
      </ul>
    </td>
  </tr>
  <tr valign=top>
    <th align=right nowrap><br>Postamble:</th>
    <td>
      <textarea rows=6 cols=70 name=postamble wrap=virtual>[philg_quote_double_quotes $postamble]</textarea><br>
      <i>(optional random text that goes after the bullet list)</i>
    </td>
  </tr>
</table>

<p><center>
<input type=submit value=\"Save Slide\">
<spacer type=horizontal size=50>
<input type=submit name=attach value=\"[wp_only_if { $role == "edit" } "Save Slide and "]View/Upload Attachments\">
</center>

<p>
Note: if you're too lazy to type and too unimaginative (like me) to
come up with new ideas you might want to
<a href=\"bulk-copy.tcl?presentation_id=$presentation_id\">copy a slide from 
another presentation</a>.

[wp_footer]
"


