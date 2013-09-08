# /www/admin/display/edit-simple-css.tcl

ad_page_contract {
    setting up cascaded style sheet properties
    @param Note: if page is accessed through /groups pages then group_id and group_vars_set are 
    already set up in the environment by the ug_serve_section. group_vars_set contains group 
    elated variables (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
    group_type_url_p, group_context_bar_list and group_navbar_list)
    
    @author gtewari@mit.edu, tarik@arsdigita.com
    @creation-date 12/26/1999

    @cvs-id edit-simple-css.tcl,v 3.2.2.7 2000/09/22 01:34:42 kevin Exp
} {
    return_url:optional
    scope:optional
    group_id:optional,integer
    user_id:optional,integer
}



ad_scope_error_check

set page_title "Edit Display Settings "

set page_content "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Display Settings"] "Edit"]
<hr>

[help_upper_right_menu]
"

if { [db_0or1row display_select_query "
     select css_bgcolor, 
            css_textcolor, 
            css_unvisited_link, 
            css_visited_link, 
            css_link_text_decoration, 
            css_font_type 
     from css_simple 
     where [ad_scope_sql]"] } {
    # the correct variables should be set now
} else {
    # there is no entry for this scope, let's go and create the default one
    set css_id [db_string display_get_id_query "select css_simple_id_sequence.nextval from dual"]
    db_dml display_insert_query "insert into css_simple 
    (css_id, [ad_scope_cols_sql], css_bgcolor, css_textcolor, css_unvisited_link, 
     css_visited_link, css_link_text_decoration, css_font_type) 
    values 
    ($css_id, [ad_scope_vals_sql], 'white', 'black', 'blue', 
     'purple', 'none', 'arial')"

    db_1row display_select_query "
    select css_bgcolor, 
           css_textcolor, 
           css_unvisited_link, 
           css_visited_link, 
           css_link_text_decoration, 
           css_font_type 
    from css_simple 
    where [ad_scope_sql]"
}

db_release_unused_handles

set color_names_list { "choose new color" Black Blue Cyan Gray Green Lime Magenta Maroon Navy Olive Purple Red Silver Teal White Yellow }
set color_values_list { "" black blue cyan gray green lime magenta maroon navy olive purple red silver teal white yellow }

#present the user with graphical options:
append html "
<form method=post action=\"edit-simple-css-2\">
[export_form_scope_vars return_url]

<table>
<tr>
<td colspan=3>&nbsp;
<th>hex value (alternative)
<tr>
<td valign=top>Body Background Color:
<td valign=top>[ad_space 2]<font color=red>$css_bgcolor</font>
<td valign=top>[ns_htmlselect -labels $color_names_list css_bgcolor $color_values_list $css_bgcolor]
<td valign=top><input type=text name=css_bgcolor_val size=8>
</tr>

<tr>
<td>Body Text Color:
<td>[ad_space 2]<font color=red>$css_textcolor</font>
<td>[ns_htmlselect -labels $color_names_list css_textcolor $color_values_list $css_textcolor]
<td><input type=text name=css_textcolor_val size=8>
</tr>

<tr>
<td>Links Color:
<td>[ad_space 2]<font color=red>$css_unvisited_link</font>
<td>[ns_htmlselect -labels $color_names_list css_unvisited_link $color_values_list $css_unvisited_link]
<td><input type=text name=css_unvisited_link_val size=8>
</tr>

<tr>
<td>Visited Links Color:
<td>[ad_space 2]<font color=red> $css_visited_link</font>
<td>[ns_htmlselect -labels $color_names_list css_visited_link $color_values_list $css_visited_link]
<td><input type=text name=css_visited_link_val size=8>
</tr>

<tr>
<td>Choose Font:
<td>[ad_space 2]<font color=red>$css_font_type</font>
<td>[ns_htmlselect -labels {"choose new font" Arial Courier Geneva Helvetica Palatino Sans-Serif Times} \
	css_font_type \
	{"" arial courier geneva helvetica palatino sans-serif times} \
	$css_font_type]
</tr>
"

if { $css_link_text_decoration == "underline" } {
    append html "
    <tr>
    <td>Links:
    <td><input type=radio name=css_link_text_decoration value=underline checked>Underlined
    <td><input type=radio name=css_link_text_decoration value=none>Not Underlined
    </tr>
    " 
} else {
    append html "
    <tr>
    <td>Links:
    <td><input type=radio name=css_link_text_decoration value=underline>Underlined
    <td><input type=radio name=css_link_text_decoration value=none checked>Not Underlined
    </tr>
    "
}

append html "
</table>
<p>
<input type=submit value=\"Update\">
</form>
"

append page_content "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_content
