# /admin/pull-down-menus/pdm-add-2.tcl
#
# Author: aure@caltech.edu, Feb 2000
#
# $Id: pdm-add-2.tcl,v 1.1.2.2 2000/04/28 15:09:19 carsten Exp $
# -----------------------------------------------------------------------------

ad_page_variables {
    {menu_id}
    {menu_key}
    {default_p}
    {orientation}
    {x_offset}
    {y_offset}
    {element_height}
    {element_width}
    {main_menu_font_style ""}
    {sub_menu_font_style ""}
    {sub_sub_menu_font_style ""}
    {main_menu_bg_img_url ""}
    {main_menu_bg_color ""}
    {main_menu_hl_img_url ""}
    {main_menu_hl_color ""}
    {sub_menu_bg_img_url ""}
    {sub_menu_bg_color ""}
    {sub_menu_hl_img_url ""}
    {sub_menu_hl_color ""}
    {sub_sub_menu_bg_img_url ""}
    {sub_sub_menu_bg_color ""}
    {sub_sub_menu_hl_img_url ""}
    {sub_sub_menu_hl_color ""}
}

# -----------------------------------------------------------------------------
# Error checking

set exception_text ""
set exception_count 0

if [empty_string_p $menu_key] {
    incr   exception_count
    append exception_text "<li>You must provide a name for the menu.\n"
}

# A help proc to check for valid integers

proc valid_integer_p {n} {
    if {[empty_string_p $n] || [regexp {[^0-9]+} $n match]} {
	return 0
    } else {
	return 1
    }
}

if ![valid_integer_p $x_offset] {
    incr   exception_count
    append exception_text "
    <li>Distance from the left of the display area is not a valid integer"  
}

if ![valid_integer_p $y_offset] {
    incr   exception_count
    append exception_text "
    <li>Distance from the top of the display area is not a valid integer"  
}

if ![valid_integer_p $element_height] {
    incr   exception_count
    append exception_text "
    <li>Element height is not a valid integer"  
}

if ![valid_integer_p $element_width] {
    incr   exception_count
    append exception_text "
    <li>Element width is not a valid integer"  
}

# use the database to check for uniqueness conflicts with menu_key 

set db [ns_db gethandle]
set menu_key_conflict_menu_id [database_to_tcl_string_or_null $db "
    select menu_id
    from   pdm_menus 
    where  menu_key = '[DoubleApos $menu_key]'"]

if {![empty_string_p $menu_key_conflict_menu_id]} {
    incr   exception_count
    append exception_text "<li>Your name conflicts with the existing menu
    \"<a href=items?menu_id=$menu_key_conflict_menu_id>$menu_key</a>\"\n"
} 

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# -----------------------------------------------------------------------------
# Done error checking.  Insert the new menu into the database and
# redirect to the admin page.

set double_click_p [database_to_tcl_string $db "
select count(*)
from   pdm_menus
where  menu_id = $menu_id"]

if {!$double_click_p} {

    ns_db dml $db "begin transaction"

    # reset all other menus to false if this one will be set true
    if {$default_p == "t"} {
	ns_db dml $db "update pdm_menus set default_p = 'f'"
    }

    ns_db dml $db "
    insert into pdm_menus ( 
        menu_id, 
        menu_key,
        default_p,
        orientation,
        x_offset, y_offset,
        element_height, 
        element_width,
        main_menu_font_style, 
        sub_menu_font_style,
        sub_sub_menu_font_style,
        main_menu_bg_img_url,
        main_menu_bg_color,
        main_menu_hl_img_url,
        main_menu_hl_color,
        sub_menu_bg_img_url,
        sub_menu_bg_color,
        sub_menu_hl_img_url,
        sub_menu_hl_color,
        sub_sub_menu_bg_img_url,
        sub_sub_menu_bg_color,
        sub_sub_menu_hl_img_url,
        sub_sub_menu_hl_color
    ) values (
        $menu_id, 
        '$QQmenu_key',
        '$default_p',
        '$orientation',
        $x_offset, 
        $y_offset,
        $element_height,
        $element_width,
        [ns_dbquotevalue $main_menu_font_style    string],
        [ns_dbquotevalue $sub_menu_font_style     string],
        [ns_dbquotevalue $sub_sub_menu_font_style string],
        [ns_dbquotevalue $main_menu_bg_img_url    string],
        [ns_dbquotevalue $main_menu_bg_color      string],
        [ns_dbquotevalue $main_menu_hl_img_url    string],
        [ns_dbquotevalue $main_menu_hl_color      string],
        [ns_dbquotevalue $sub_menu_bg_img_url     string],
        [ns_dbquotevalue $sub_menu_bg_color       string],
        [ns_dbquotevalue $sub_menu_hl_img_url     string],
        [ns_dbquotevalue $sub_menu_hl_color       string],
        [ns_dbquotevalue $sub_sub_menu_bg_img_url string],
        [ns_dbquotevalue $sub_sub_menu_bg_color   string],
        [ns_dbquotevalue $sub_sub_menu_hl_img_url string],
        [ns_dbquotevalue $sub_sub_menu_hl_color   string]
    )"

    ns_db dml $db "end transaction"
}

ad_returnredirect ""




