# $Id: edit-simple-css-2.tcl,v 3.0.4.1 2000/04/28 15:08:34 carsten Exp $
# File:     /admin/css/edit-simple-css-2.tcl
# Date:     12/26/99
# Author:   gtewari@mit.edu (revised by tarik@arsdigita.com)
# Contact:  tarik@arsdigita.com
# Purpose:  setting up cascaded style sheet properties
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# css_bgcolor, css_textcolor, css_unvisited_link, css_visited_link, css_link_text_decoration, css_font_type
# css_bgcolor_val, css_textcolor_val, css_unvisited_link_val, css_visited_link_val
# maybe return_url
# maybe scope, maybe scope related variables (group_id, user_id)

if { ![info exists return_url] } {
    set return_url "edit-simple-css.tcl"
}

ad_scope_error_check

set db [ns_db gethandle]

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


ns_db dml $db $update_sql

ns_db releasehandle $db

ad_returnredirect $return_url



