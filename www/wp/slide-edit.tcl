# /wp/slide-edit.tcl
ad_page_contract {
    Allows the user to create or edit a slide.
    @cvs-id slide-edit.tcl,v 3.4.2.10 2001/01/12 00:48:26 khy Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param  presentation_id (if creating)
    @param slide_id (to edit) 
    @param sort_key (to create)
} {
    presentation_id:naturalnum,optional
    slide_id:naturalnum,optional
    sort_key:optional
} 

if { ![info exists slide_id] && ![info exists presentation_id] } {
    ad_return_error "Error" "presentation_id or slide_id must be supplied."
}

set user_id [ad_maybe_redirect_for_registration]

set preamble_columns 70
set postamble_columns 70
if { [info exists slide_id] } {
    # Editing an existing slide.
    if {[catch {db_1row slide_sel "
    select  presentation_id, sort_key,
    title,		
    preamble,
    bullet_items,
    postamble
    from wp_slides where slide_id = :slide_id"}]} {
	ad_return_error "Error" "Slide $slide_id does not exist in the database."
	return
    }
    set role "Edit"
} else {
 
    # Creating a new slide.
    foreach var { title preamble bullet_items postamble } {
	set $var ""
    }
    set slide_id [wp_nextval "wp_ids"]
    set creating "t"

    set role "Create"
}

wp_check_authorization $presentation_id $user_id "write"

##### Determine number of lines in preamble and postamble so that we can adjust the height of the  
##### text boxes accordingly
set preamble_temp $preamble
set preamble_numlines 0
while {[expr {[set index [string first "\n" $preamble_temp]] >= 0 || [string length $preamble_temp] > 0}]} {
    incr preamble_numlines
    if { $preamble_numlines > 15 } then { break }
    if {[expr {$index > $preamble_columns || $index < 0}]} {
	set preamble_temp [string range $preamble_temp $preamble_columns end]
    } else {
	set preamble_temp [string range $preamble_temp [expr $index + 1] end]
    }
}
set preamble_numlines [expr [expr $preamble_numlines > 2] ? [expr $preamble_numlines + 2] : 4 ]
set postamble_temp $postamble

set postamble_numlines 0
while {[expr {[set index [string first "\n" $postamble_temp]] >= 0 || [string length $postamble_temp] > 0}]} {
    incr postamble_numlines
    if { $postamble_numlines > 15 } then { break }
    if {[expr {$index > $postamble_columns || $index < 0}]} {
	set postamble_temp [string range $postamble_temp $postamble_columns end]
    } else {
	set postamble_temp [string range $postamble_temp [expr $index + 1] end]
    }
}
set postamble_numlines [expr [expr $postamble_numlines > 2] ? [expr $postamble_numlines + 2] : 4 ]
###

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
	append bullet_items_html "<textarea wrap=soft rows=$rows cols=60 name=bullet.[expr $i + 1]>[philg_quote_double_quotes $value]</textarea>"
    } else {
	append bullet_items_html "<input type=text size=60 name=bullet.[expr $i + 1] value=\"[philg_quote_double_quotes $value]\">"
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

set page_output "
[wp_header_form "name=f action=slide-edit-2 method=post" [list "" "WimpyPoint"] [list "index?show_user=" "Your Presentations"] \
  [list "presentation-top?presentation_id=$presentation_id" [db_string select_title "select title from wp_presentations where presentation_id = :presentation_id"]] "$role a Slide"]

[export_form_vars presentation_id sort_key creating]
[export_form_vars -sign slide_id]
<script language=javascript>
function swapWithNext(index)
{
  var val = document.f\['bullet.' + index\].value;
  document.f\['bullet.' + index\].value = document.f\['bullet.' + (index+1)\].value;
  document.f\['bullet.' + (index+1)\].value = val;
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
      <textarea rows=$preamble_numlines cols=70 name=preamble wrap=virtual>[philg_quote_double_quotes $preamble]</textarea><br>
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
      <textarea rows=$postamble_numlines cols=70 name=postamble wrap=virtual>[philg_quote_double_quotes $postamble]</textarea><br>
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
<a href=\"bulk-copy?presentation_id=$presentation_id\">copy a slide from 
another presentation</a>.

[wp_footer]
"



doc_return  200 "text/html" $page_output