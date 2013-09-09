# /homepage/update-display-2.tcl

ad_page_contract {

    Update display settings according to user's submission.

    @param filesystem_node The top directory displayed (passed argument).

    @param bgcolor The user selected background color.
    @param bgcolor_val The user typed background color.
    @param maint_bgcolor The user selected background color for the maintenance pages.
    @param maint_bgcolor_val The user typed background color for the maintenance page.

    @param textcolor The user selected text color.
    @param textcolor_val The user typed text color.
    @param maint_textcolor The user selected text color for the maintenance pages.
    @param maint_textcolor_val The user typed text color for the maintenance page.
    
    @param unvisited_link The user selected unvisited link color.
    @param unvisited_link_val The user typed unvisited link color.
    @param maint_unvisited_link The user selected unvisited link color for the maintenance pages.
    @param maint_unvisited_link_val The user typed unvisited link color for the maintenance page.

    @param visited_link The user selected visited link color.
    @param visited_link_val The user typed visited link color.
    @param maint_visited_link The user selected visited link color for the maintenance pages.
    @param maint_visited_link_val The user typed visited link color for the maintenance page.

    @font_type The user selected font typed.
    @link_font_weight The user chosen font weight (regular or bold).
    @link_text_decoration The user chosen font weight (regular or underlined).

    @maint_font_type The user selected font typed for the maintenance pages.
    @maint_link_font_weight The user chosen font weight (regular or bold) for the maintenance pages.
    @maint_link_text_decoration The user chosen font weight (regular or underlined) for the maintenance pages.

    @author mobin@mit.edu
    @cvs-id update-display-2.tcl,v 3.2.2.5 2000/07/23 22:32:43 namin Exp
} {
    filesystem_node:notnull,naturalnum
    bgcolor
    textcolor
    unvisited_link
    visited_link
    bgcolor_val
    textcolor_val
    unvisited_link_val
    visited_link_val
    font_type
    link_font_weight
    link_text_decoration
    maint_bgcolor
    maint_textcolor
    maint_unvisited_link
    maint_visited_link
    maint_bgcolor_val    
    maint_textcolor_val
    maint_unvisited_link_val
    maint_visited_link_val
    maint_font_type
    maint_link_font_weight
    maint_link_text_decoration
}


set user_id [ad_maybe_redirect_for_registration]


set sql_update_set [list]

set vars_list [list bgcolor textcolor unvisited_link visited_link maint_bgcolor maint_textcolor maint_unvisited_link maint_visited_link font_type link_text_decoration link_font_weight maint_font_type maint_link_text_decoration maint_link_font_weight]

foreach var $vars_list {
    if { [exists_and_not_null $var] } {

	lappend sql_update_set "$var = :$var"

    } elseif { [exists_and_not_null ${var}_val] } {
	if {[string length [set ${var}_val]] > 20} {
	    ad_return_complaint 1 "The hex value for $var should be not more than 20 characters long."
	    return
	} else {
	    lappend sql_update_set "$var = :${var}_val"
	}
    }
}

if { [llength $sql_update_set] > 0 } {

    set sql_update "update users_homepages
    set [join $sql_update_set ", \n"]
    where user_id=:user_id
    "
    db_dml display_update $sql_update
}

db_release_unused_handles

ad_returnredirect "index?filesystem_node=$filesystem_node"

