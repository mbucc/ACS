# /www/admin/display/edit-simple-css-2.tcl

ad_page_contract {

    setting up cascaded style sheet properties

    @author gtewari@mit.edu, tarik@arsdigita.com
    @creation-date 12/26/1999
    @param css_bgcolor 
    @param css_textcolor 
    @param css_unvisited_link 
    @param css_visited_link 
    @param css_link_text_decoration 
    @param css_font_type 
    @param css_bgcolor_val 
    @param css_textcolor_val 
    @param css_unvisited_link_val 
    @param css_visited_link_val

    @cvs-id edit-simple-css-2.tcl,v 3.2.2.7 2000/07/25 11:27:53 ron Exp
} {
    css_bgcolor 
    css_textcolor 
    css_unvisited_link 
    css_visited_link 
    css_link_text_decoration 
    css_font_type 
    css_bgcolor_val 
    css_textcolor_val 
    css_unvisited_link_val 
    css_visited_link_val
    return_url:optional
    scope:optional
    group_id:optional,integer
    user_id:optional,integer
}

if { ![info exists return_url] } {
    set return_url "edit-simple-css"
}

ad_scope_error_check

append update_sql "
update css_simple
set "

if { ([info exists css_bgcolor] && ![empty_string_p $css_bgcolor]) || \
	([info exists css_bgcolor_val] && ![empty_string_p $css_bgcolor_val]) } {
    append update_sql "css_bgcolor = [ad_decode $css_bgcolor_val "" '$css_bgcolor' '$css_bgcolor_val'],
    "
}

if { ([info exists css_textcolor] && ![empty_string_p $css_textcolor]) || \
	([info exists css_textcolor_val] && ![empty_string_p $css_textcolor_val]) } {
    append update_sql "css_textcolor = [ad_decode $css_textcolor_val "" '$css_textcolor' '$css_textcolor_val'],
    "
}

if { ([info exists css_unvisited_link] && ![empty_string_p $css_unvisited_link]) || \
	([info exists css_unvisited_link_val] && ![empty_string_p $css_unvisited_link_val]) } {
    append update_sql "css_unvisited_link = [ad_decode $css_unvisited_link_val "" '$css_unvisited_link' '$css_unvisited_link_val'],
    "
}

if { ([info exists css_visited_link] && ![empty_string_p $css_visited_link]) || \
	([info exists css_visited_link_val] && ![empty_string_p $css_visited_link_val]) } {
    append update_sql "css_visited_link = [ad_decode $css_visited_link_val "" '$css_visited_link' '$css_visited_link_val'],
    "
}

if { [info exists css_font_type] && ![empty_string_p $css_font_type] } {
    append update_sql "css_font_type = '$css_font_type',
    "
}

append update_sql "css_link_text_decoration = '$css_link_text_decoration'
where [ad_scope_sql]
"

db_dml display_update_query $update_sql

db_release_unused_handles

ad_returnredirect $return_url







