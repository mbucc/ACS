# /www/admin/pull-down-menus/pdm-add-2.tcl
ad_page_contract {

  Creates new menu group.

  @param menu_id             id of new menu
  @param menu_key            menu title
  @param default_p           whether this will be default menu
  @param orientation         horizontal or vertical
  @param x_offset            distance from the left side of the display area
  @param y_offset            distance from top of the display area
  @param element_height      dimension of a single menu element
  @param element_width       dimension of a single menu element
  @param main_menu_font_style     main menu font style
  @param sub_menu_font_style      first-level pull-down font style
  @param sub_sub_menu_font_style  second-level pull-down font style
  @param main_menu_bg_img_url     main menu row background image URL
  @param main_menu_bg_color       main menu row background color
  @param main_menu_hl_img_url     main menu row highlight image URL
  @param main_menu_hl_color       main menu row highlight color
  @param sub_menu_bg_img_url      1st level pull-down background image URL
  @param sub_menu_bg_color        1st level pull-down background color
  @param sub_menu_hl_img_url      1st level pull-down highlight image URL
  @param sub_menu_hl_color        1st level pull-down highlight color
  @param sub_sub_menu_bg_img_url  2nd level pull-down background image URL
  @param sub_sub_menu_bg_color    2nd level pull-down background color
  @param sub_sub_menu_hl_img_url  2nd level pull-down highlight image URL
  @param sub_sub_menu_hl_color    2nd level pull-down highlight color

  @author aure@caltech.edu
  @creation-date Feb 2000
  @cvs-id pdm-add-2.tcl,v 1.4.2.7 2001/01/11 23:37:22 khy Exp

} {

    menu_id:integer,notnull,verify
    menu_key:notnull
    default_p:notnull
    orientation:notnull
    x_offset:integer,notnull
    y_offset:integer,notnull
    element_height:integer,notnull
    element_width:integer,notnull
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
} -errors {
    menu_key:notnull {
	You must specify a menu name
    }
    y_offset:notnull {
	You must specify the distance from the top of the display
    }
    y_offset:integer {
	The distance from the top of the display must be an integer
    }
    x_offset:notnull {
	You must specify the distance from the left of the display
    }
    x_offset:integer {
	The distance from the left of the display must be an integer
    }
    element_height:notnull {
	You must specify the element height
    }
    element_height:integer {
	The element height must be an integer
    }
    element_width:notnull {
	You must specify the element width
    }
    element_width:integer {
	The element width must be an integer
    }
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

if { [string length $menu_key] > 20 } {
    incr   exception_count
    append exception_text "
    <li>Menu name longer than 20 chars"
}

# use the database to check for uniqueness conflicts with menu_key 

set menu_key_conflict_menu_id [db_string conflict_menu_id "
    select menu_id
    from   pdm_menus 
    where  menu_key = :menu_key" -default "" ]

if {![empty_string_p $menu_key_conflict_menu_id]} {
    incr   exception_count
    append exception_text "<li>Your name conflicts with the existing menu
    \"<a href=items?menu_id=$menu_key_conflict_menu_id>$menu_key</a>\"\n"
} 

if { $exception_count > 0 } {
    db_release_unused_handles
    ad_return_complaint $exception_count $exception_text
    return 0
}

# -----------------------------------------------------------------------------
# Done error checking.  Insert the new menu into the database and
# redirect to the admin page.

set double_click_p [db_string double_click_check "
select count(*)
from   pdm_menus
where  menu_id = :menu_id" ]

if {!$double_click_p} {

    db_transaction {

    # reset all other menus to false if this one will be set true
    if {$default_p == "t"} {
	db_dml reset_default_flag_for_all_menus "update pdm_menus set default_p = 'f'"
	# flush the current default menu - it will get memoized again when it's next called
	util_memoize_flush "ad_pdm_helper \"\" \"\" \"\" 1"
    }

    db_dml new_menu "
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
        :menu_id, 
        :menu_key,
        :default_p,
        :orientation,
        :x_offset, 
        :y_offset,
        :element_height,
        :element_width,
        :main_menu_font_style,
        :sub_menu_font_style,
        :sub_sub_menu_font_style,
        :main_menu_bg_img_url,
        :main_menu_bg_color,
        :main_menu_hl_img_url,
        :main_menu_hl_color,
        :sub_menu_bg_img_url,
        :sub_menu_bg_color,
        :sub_menu_hl_img_url,
        :sub_menu_hl_color,
        :sub_sub_menu_bg_img_url,
        :sub_sub_menu_bg_color,
        :sub_sub_menu_hl_img_url,
        :sub_sub_menu_hl_color
    )" 

    }
}

db_release_unused_handles
ad_returnredirect ""

