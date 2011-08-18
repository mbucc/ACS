# $Id: get-display.tcl,v 3.0 2000/02/06 03:46:42 ron Exp $
set_form_variables
# maint_p, user_id

#if {![info exists user_id] || [empty_string_p $user_id]} {
    # First, we need to get the user_id
#    set user_id [ad_verify_and_get_user_id]
#}

if {![info exists maint_p] || [empty_string_p $maint_p]} {
    set maint_p 1
}

set db [ns_db gethandle]

if {$maint_p == 0} {
    set selection [ns_db 0or1row $db "
    select bgcolor, 
    textcolor, 
    unvisited_link, 
    visited_link, 
    link_text_decoration, 
    link_font_weight,
    font_type
    from users_homepages
    where user_id=$user_id
    "]
} else {
    set selection [ns_db 0or1row $db "
    select maint_bgcolor as bgcolor, 
    maint_textcolor as textcolor, 
    maint_unvisited_link as unvisited_link, 
    maint_visited_link as visited_link, 
    maint_link_text_decoration as link_text_decoration,
    maint_link_font_weight as link_font_weight,
    maint_font_type as font_type
    from users_homepages
    where user_id=$user_id
    "]
}
if { [empty_string_p $selection] } {
    # initialize background color to white
    ns_return 200 text/css "BODY { background-color: white }
    "
    return
}    

set_variables_after_query

if { ![empty_string_p $bgcolor] } {
    set style_bgcolor "background-color: $bgcolor"
}

if { ![empty_string_p $textcolor] } {
    set style_textcolor "color: $textcolor"
}

if { ![empty_string_p $unvisited_link] } {
    set style_unvisited_link "color: $unvisited_link"
}

if { ![empty_string_p $visited_link] } {
    set style_visited_link "color: $visited_link"
}

if { ![empty_string_p $link_text_decoration] } {
    set style_link_text_decoration "text-decoration: $link_text_decoration"
}

if { ![empty_string_p $link_font_weight] } {
    set style_link_font_weight "font-weight: $link_font_weight"
}

if { ![empty_string_p $font_type] } {
    set style_font_type "font-family: $font_type"
}

set a_string [join [css_list_existing style_link_text_decoration style_unvisited_link style_link_font_weight] "; "]
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


