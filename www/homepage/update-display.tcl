# /homepage/update-display.tcl

ad_page_contract {

    Allow user to update display settings.

    @param filesystem_node The top directory displayed (passed argument).

    @author mobin@mit.edu
    @cvs-id update-display.tcl,v 3.2.2.6 2000/09/22 01:38:19 kevin Exp
} {
    filesystem_node:naturalnum,notnull
}

set document ""


set user_id [ad_maybe_redirect_for_registration]

set title "Display Settings "

append document "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws [list "index.tcl?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>

[help_upper_right_menu]
"

db_0or1row user_homepage {
select user_id,
       bgcolor, 
       textcolor, 
       unvisited_link, 
       visited_link, 
       link_text_decoration, 
       link_font_weight, 
       font_type,
       maint_bgcolor,
       maint_textcolor, 
       maint_unvisited_link, 
       maint_visited_link, 
       maint_link_text_decoration, 
       maint_link_font_weight, 
       maint_font_type
from users_homepages
where user_id=:user_id
}

db_release_unused_handles

set color_names_list { "choose new color" Black Blue Cyan Gray Green Lime Magenta Maroon Navy Olive Purple Red Silver Teal White Yellow }
set color_values_list { "" black blue cyan gray green lime magenta maroon navy olive purple red silver teal white yellow }

# Present the user with graphical options:
append html "
<form method=post action=update-display-2>
[export_form_vars filesystem_node]
<font size=+1>Public Pages:</font>
<table>
<tr>
<td colspan=3>&nbsp;
<th>hex value (alternative)
<tr>
<td>Body Background Color:
<td><font color=red>$bgcolor</font>
<td>[ns_htmlselect -labels $color_names_list bgcolor $color_values_list $bgcolor]
<td><input type=text name=bgcolor_val size=8 maxlength=20>
</tr>

<tr>
<td>Body Text Color:
<td>[ad_space 2]<font color=red>$textcolor</font>
<td>[ns_htmlselect -labels $color_names_list textcolor $color_values_list $textcolor]
<td><input type=text name=textcolor_val size=8 maxlength=20>
</tr>

<tr>
<td>Links Color:
<td>[ad_space 2]<font color=red>$unvisited_link</font>
<td>[ns_htmlselect -labels $color_names_list unvisited_link $color_values_list $unvisited_link]
<td><input type=text name=unvisited_link_val size=8 maxlength=20>
</tr>

<tr>
<td>Visited Links Color:
<td>[ad_space 2]<font color=red> $visited_link</font>
<td>[ns_htmlselect -labels $color_names_list visited_link $color_values_list $visited_link]
<td><input type=text name=visited_link_val size=8 maxlength=20>
</tr>

<tr>
<td>Choose Font:
<td>[ad_space 2]<font color=red>$font_type</font>
<td>[ns_htmlselect -labels {"choose new font" Arial Courier Geneva Helvetica Palatino Sans-Serif Times} \
	font_type \
	{"" arial courier geneva helvetica palatino sans-serif times} \
	$font_type]
</tr>
"

if { $link_text_decoration == "none" } {
    append html "
    <tr>
    <td>Links:
    <td><input type=radio name=link_text_decoration value=underline>Underlined
    <td><input type=radio name=link_text_decoration value=none checked>Not Underlined
    </tr>
    "
} else {
    append html "
    <tr>
    <td>Links:
    <td><input type=radio name=link_text_decoration value=underline checked>Underlined
    <td><input type=radio name=link_text_decoration value=none>Not Underlined
    </tr>
    " 
}

if { $link_font_weight == "none" || [empty_string_p $link_font_weight] } {
    append html "
    <tr>
    <td>Links weight:
    <td><input type=radio name=link_font_weight value=bold>Bold
    <td><input type=radio name=link_font_weight value=none checked>Normal
    </tr>
    "
} else {
    append html "
    <tr>
    <td>Links weight:
    <td><input type=radio name=link_font_weight value=bold checked>Bold
    <td><input type=radio name=link_font_weight value=none>Normal
    </tr>
    " 
}

append html "</table><br><p>"

# For Maintenance Pages
append html "
<p>
<font size=+1>Maintenance Pages:</font>
<table border=0 cellpadding=0 cellspacing=0>
<tr>
<td colspan=3>&nbsp;
<th>hex value (alternative)
<tr>
<td>Body Background Color:
<td><font color=red>$maint_bgcolor</font>
<td>[ns_htmlselect -labels $color_names_list maint_bgcolor $color_values_list $maint_bgcolor]
<td><input type=text name=maint_bgcolor_val size=8 maxlength=20>
</tr>

<tr>
<td>Body Text Color:
<td>[ad_space 2]<font color=red>$maint_textcolor</font>
<td>[ns_htmlselect -labels $color_names_list maint_textcolor $color_values_list $maint_textcolor]
<td><input type=text name=maint_textcolor_val size=8 maxlength=20>
</tr>

<tr>
<td>Links Color:
<td>[ad_space 2]<font color=red>$maint_unvisited_link</font>
<td>[ns_htmlselect -labels $color_names_list maint_unvisited_link $color_values_list $maint_unvisited_link]
<td><input type=text name=maint_unvisited_link_val size=8 maxlength=20>
</tr>

<tr>
<td>Visited Links Color:
<td>[ad_space 2]<font color=red>$maint_visited_link</font>
<td>[ns_htmlselect -labels $color_names_list maint_visited_link $color_values_list $maint_visited_link]
<td><input type=text name=maint_visited_link_val size=8 maxlength=20>
</tr>

<tr>
<td>Choose Font:
<td>[ad_space 2]<font color=red>$maint_font_type</font>
<td>[ns_htmlselect -labels {"choose new font" Arial Courier Geneva Helvetica Palatino Sans-Serif Times} \
	maint_font_type \
	{"" arial courier geneva helvetica palatino sans-serif times} \
	$maint_font_type]
</tr>
"

if { $maint_link_text_decoration == "none" } {
    append html "
    <tr>
    <td>Links:
    <td><input type=radio name=maint_link_text_decoration value=underline>Underlined
    <td><input type=radio name=maint_link_text_decoration value=none checked>Not Underlined
    </tr>
    "
} else {
    append html "
    <tr>
    <td>Links:
    <td><input type=radio name=maint_link_text_decoration value=underline checked>Underlined
    <td><input type=radio name=maint_link_text_decoration value=none>Not Underlined
    </tr>
    " 
}

if { $maint_link_font_weight == "none" || [empty_string_p $maint_link_font_weight] } {
    append html "
    <tr>
    <td>Links weight:
    <td><input type=radio name=maint_link_font_weight value=bold>Bold
    <td><input type=radio name=maint_link_font_weight value=none checked>Normal
    </tr>
    "
} else {
    append html "
    <tr>
    <td>Links weight:
    <td><input type=radio name=maint_link_font_weight value=bold checked>Bold
    <td><input type=radio name=maint_link_font_weight value=none>Normal
    </tr>
    " 
}

append html "
</table>
<p>
<table><tr><td><input type=submit value=\"Update\"></form></td><td>
<form method=post action=update-display-3>
[export_form_vars filesystem_node]
<input type=submit value=\"Delete Customizations\"></form>
</td></tr></table>
"

append document "
<blockquote>
$html
</blockquote>
[ad_footer]
"
doc_return  200 text/html $document
