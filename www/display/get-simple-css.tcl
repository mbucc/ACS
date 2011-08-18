# $Id: get-simple-css.tcl,v 3.0 2000/02/06 03:37:50 ron Exp $
# File:     /css/get-simple-css.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  gets css from the database and returns the css file
#           this file uses css_simple table
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
select css_bgcolor, css_textcolor, css_unvisited_link, css_visited_link, css_link_text_decoration, css_font_type
from css_simple
where [ad_scope_sql]
"]

if { [empty_string_p $selection] } {
    # initialize background color to white
    ns_return 200 text/css "BODY { background-color: white }
    "
    return
}    

set_variables_after_query

if { ![empty_string_p $css_bgcolor] } {
    set style_bgcolor "background-color: $css_bgcolor"
}

if { ![empty_string_p $css_textcolor] } {
    set style_textcolor "color: $css_textcolor"
}

if { ![empty_string_p $css_unvisited_link] } {
    set style_unvisited_link "color: $css_unvisited_link"
}

if { ![empty_string_p $css_visited_link] } {
    set style_visited_link "color: $css_visited_link"
}

if { ![empty_string_p $css_link_text_decoration] } {
    set style_link_text_decoration "text-decoration: $css_link_text_decoration"
}

if { ![empty_string_p $css_font_type] } {
    set style_font_type "font-family: $css_font_type"
}

set a_string [join [css_list_existing style_link_text_decoration style_unvisited_link] "; "]
append css [ad_decode $a_string "" "" "A { $a_string }\n"]

set a_hover_string  [join [css_list_existing style_link_text_decoration] "; "]
append css [ad_decode $a_hover_string "" "" "A:hover { $a_hover_string }\n"]

set a_visited_string [join [css_list_existing style_visited_link style_link_text_decoration] "; "]
append css [ad_decode $a_visited_string "" "" "A:visited { $a_visited_string }\n"]

set font_string [join [css_list_existing style_font_type style_textcolor] "; "]
if { ![empty_string_p $font_string] } {
    append css "P  { $font_string }
UL { $font_string }
H1 { $font_string }
H2 { $font_string }
H3 { $font_string }
H4 { $font_string }
TH { $font_string }
TD { $font_string }
BLOCKQUOTE{ $font_string }
"
}

set body_string [join [css_list_existing style_bgcolor style_textcolor style_font_type] "; "]
append css [ad_decode $body_string "" "" "BODY { $body_string }"]

ns_db releasehandle $db 
ns_return 200 text/css $css


