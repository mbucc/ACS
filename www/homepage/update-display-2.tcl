# $Id: update-display-2.tcl,v 3.0.4.1 2000/04/28 15:11:04 carsten Exp $
set_the_usual_form_variables
# bgcolor, textcolor, unvisited_link, visited_link, link_text_decoration, font_type
# bgcolor_val, textcolor_val, unvisited_link_val, visited_link_val
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

append update_sql "
update users_homepages
set "


if { ([info exists bgcolor] && ![empty_string_p $bgcolor]) || \
	([info exists bgcolor_val] && ![empty_string_p $bgcolor_val]) } {
    append update_sql "bgcolor = [ad_decode $bgcolor_val "" '$bgcolor' '$bgcolor_val'],
    "
}

if { ([info exists textcolor] && ![empty_string_p $textcolor]) || \
	([info exists textcolor_val] && ![empty_string_p $textcolor_val]) } {
    append update_sql "textcolor = [ad_decode $textcolor_val "" '$textcolor' '$textcolor_val'],
    "
}

if { ([info exists unvisited_link] && ![empty_string_p $unvisited_link]) || \
	([info exists unvisited_link_val] && ![empty_string_p $unvisited_link_val]) } {
    append update_sql "unvisited_link = [ad_decode $unvisited_link_val "" '$unvisited_link' '$unvisited_link_val'],
    "
}

if { ([info exists visited_link] && ![empty_string_p $visited_link]) || \
	([info exists visited_link_val] && ![empty_string_p $visited_link_val]) } {
    append update_sql "visited_link = [ad_decode $visited_link_val "" '$visited_link' '$visited_link_val'],
    "
}

if { [info exists font_type] && ![empty_string_p $font_type] } {
    append update_sql "font_type = '$font_type',
    "
}





if { ([info exists maint_bgcolor] && ![empty_string_p $maint_bgcolor]) || \
	([info exists maint_bgcolor_val] && ![empty_string_p $maint_bgcolor_val]) } {
    append update_sql "maint_bgcolor = [ad_decode $maint_bgcolor_val "" '$maint_bgcolor' '$maint_bgcolor_val'],
    "
}

if { ([info exists maint_textcolor] && ![empty_string_p $maint_textcolor]) || \
	([info exists maint_textcolor_val] && ![empty_string_p $maint_textcolor_val]) } {
    append update_sql "maint_textcolor = [ad_decode $maint_textcolor_val "" '$maint_textcolor' '$maint_textcolor_val'],
    "
}

if { ([info exists maint_unvisited_link] && ![empty_string_p $maint_unvisited_link]) || \
	([info exists maint_unvisited_link_val] && ![empty_string_p $maint_unvisited_link_val]) } {
    append update_sql "maint_unvisited_link = [ad_decode $maint_unvisited_link_val "" '$maint_unvisited_link' '$maint_unvisited_link_val'],
    "
}

if { ([info exists maint_visited_link] && ![empty_string_p $maint_visited_link]) || \
	([info exists maint_visited_link_val] && ![empty_string_p $maint_visited_link_val]) } {
    append update_sql "maint_visited_link = [ad_decode $maint_visited_link_val "" '$maint_visited_link' '$maint_visited_link_val'],
    "
}

if { [info exists maint_font_type] && ![empty_string_p $maint_font_type] } {
    append update_sql "maint_font_type = '$maint_font_type',
    "
}

append update_sql "link_text_decoration = '$link_text_decoration',
maint_link_text_decoration = '$maint_link_text_decoration',
link_font_weight = '$link_font_weight',
maint_link_font_weight = '$maint_link_font_weight'
where user_id=$user_id
"

ns_db dml $db $update_sql

ns_db releasehandle $db

ad_returnredirect "index.tcl?filesystem_node=$filesystem_node"








