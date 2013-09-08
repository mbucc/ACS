# /homepage/get-display.tcl

ad_page_contract {
    Get the display style for the page.
    
    @param user_id The user_id related to the requested display settings.
    @param maint_p Wether requesting the maintenance or regular display settings. 

    @creation-date January 2000
    @author mobin@mit.edu
    @cvs-id get-display.tcl,v 3.1.2.5 2000/09/22 01:38:16 kevin Exp
} {
    user_id:notnull,naturalnum
    {maint_p "1"}
}

if {$maint_p == 0} {
    set returned_row_p [db_0or1row display {
    select bgcolor, 
    textcolor, 
    unvisited_link, 
    visited_link, 
    link_text_decoration, 
    link_font_weight,
    font_type
    from users_homepages
    where user_id=:user_id
    }]
} else {
    set returned_row_p [db_0or1row maint_display {
    select maint_bgcolor as bgcolor, 
    maint_textcolor as textcolor, 
    maint_unvisited_link as unvisited_link, 
    maint_visited_link as visited_link, 
    maint_link_text_decoration as link_text_decoration,
    maint_link_font_weight as link_font_weight,
    maint_font_type as font_type
    from users_homepages
    where user_id=:user_id
    }]
}

if { $returned_row_p == 0 } {
    # initialize background color to white
    doc_return  200 text/css "BODY { background-color: white }
    "
    return
}    


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

db_release_unused_handles 
doc_return 200 text/css $css