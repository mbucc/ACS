# $Id: update-display.tcl,v 3.0 2000/02/06 03:47:18 ron Exp $
set_form_variables
# filesystem_node

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

set db [ns_db gethandle]

ReturnHeaders

set title "Display Settings "

ns_write "
[ad_header $title]
<h2>$title</h2>
[ad_context_bar_ws [list "index.tcl?filesystem_node=$filesystem_node" "Homepage Maintenance"] $title]
<hr>

[help_upper_right_menu]
"

set selection [ns_db 0or1row $db "
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
where user_id=$user_id"]

#if { [empty_string_p $selection] }  {
    # there is no entry for this scope, let's go and create the default one
#    ns_db dml $db "
#    insert into simple
#    (id, [ad_scope_cols_sql], bgcolor, textcolor, unvisited_link, visited_link, 
#     link_text_decoration, font_type)
#    values
#    (simple_id_sequence.nextval, [ad_scope_vals_sql], 'white', 'black', 'blue', 'purple', 'none', 'arial')
#    "

#    set selection [ns_db 1row $db "
#    select bgcolor, textcolor, unvisited_link, visited_link, link_text_decoration, font_type
#    from simple
#    where [ad_scope_sql]
#    "]
#}
 
set_variables_after_query

set color_names_list { "choose new color" Black Blue Cyan Gray Green Lime Magenta Maroon Navy Olive Purple Red Silver Teal White Yellow }
set color_values_list { "" black blue cyan gray green lime magenta maroon navy olive purple red silver teal white yellow }

#present the user with graphical options:
append html "
<form method=post action=update-display-2.tcl>
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
<td><input type=text name=bgcolor_val size=8>
</tr>

<tr>
<td>Body Text Color:
<td>[ad_space 2]<font color=red>$textcolor</font>
<td>[ns_htmlselect -labels $color_names_list textcolor $color_values_list $textcolor]
<td><input type=text name=textcolor_val size=8>
</tr>

<tr>
<td>Links Color:
<td>[ad_space 2]<font color=red>$unvisited_link</font>
<td>[ns_htmlselect -labels $color_names_list unvisited_link $color_values_list $unvisited_link]
<td><input type=text name=unvisited_link_val size=8>
</tr>

<tr>
<td>Visited Links Color:
<td>[ad_space 2]<font color=red> $visited_link</font>
<td>[ns_htmlselect -labels $color_names_list visited_link $color_values_list $visited_link]
<td><input type=text name=visited_link_val size=8>
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
<td><input type=text name=maint_bgcolor_val size=8>
</tr>

<tr>
<td>Body Text Color:
<td>[ad_space 2]<font color=red>$maint_textcolor</font>
<td>[ns_htmlselect -labels $color_names_list maint_textcolor $color_values_list $maint_textcolor]
<td><input type=text name=maint_textcolor_val size=8>
</tr>

<tr>
<td>Links Color:
<td>[ad_space 2]<font color=red>$maint_unvisited_link</font>
<td>[ns_htmlselect -labels $color_names_list maint_unvisited_link $color_values_list $maint_unvisited_link]
<td><input type=text name=maint_unvisited_link_val size=8>
</tr>

<tr>
<td>Visited Links Color:
<td>[ad_space 2]<font color=red>$maint_visited_link</font>
<td>[ns_htmlselect -labels $color_names_list maint_visited_link $color_values_list $maint_visited_link]
<td><input type=text name=maint_visited_link_val size=8>
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
<form method=post action=update-display-3.tcl>
[export_form_vars filesystem_node]
<input type=submit value=\"Delete Customizations\"></form>
</td></tr></table>
"

ns_write "
<blockquote>
$html
</blockquote>
[ad_footer]
"
















