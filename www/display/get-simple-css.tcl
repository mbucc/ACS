# /www/display/get-simple-css.tcl

ad_page_contract {
    gets css from the database and returns the css file
    this file uses css_simple table
    
    Note: if page is accessed through /groups pages then group_id and group_vars_set are already 
    set up in the environment by the ug_serve_section. group_vars_set contains group related 
    variables (group_id, group_name, group_short_name, group_admin_email, group_public_url, 
    group_admin_url, group_public_root_url, group_admin_root_url, group_type_url_p, 
    group_context_bar_list and group_navbar_list)
    
    @author tarik@arsdigita.com
    @creation-date 12/22/1999

    @cvs-id get-simple-css.tcl,v 3.1.2.7 2000/09/22 01:37:22 kevin Exp
} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    on_which_group_id:optional
    on_what_id:optional
}


ad_scope_error_check

if { [db_0or1row display_info_query "
       select css_bgcolor, 
              css_textcolor, 
              css_unvisited_link, 
              css_visited_link, 
	      css_link_text_decoration, 
              css_font_type 
       from css_simple 
       where [ad_scope_sql]"] } {
    # correct variables will be initialized
} else {
    # initialize background color to white
    doc_return  200 text/css "BODY { background-color: white }"
    return
}

db_release_unused_handles 


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


doc_return 200 text/css $css






