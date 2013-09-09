# /www/pull-down-menus/style.tcl
ad_page_contract {

    Gets the navbar style parameters from the database and
    outputs a cascading style sheet.

    @param menu_id menu group to be displayed
    @author aure@arsdigita.com
    @creation-date Feb 2000
    @cvs-id style.tcl,v 1.4.2.5 2000/09/22 01:39:08 kevin Exp
} {
    menu_id:integer
}

db_1row menu "
    select main_menu_font_style, 
           sub_menu_font_style, 
           sub_sub_menu_font_style,
           main_menu_bg_img_url, 
           sub_menu_bg_img_url, 
           main_menu_hl_img_url, 
           sub_menu_hl_img_url,
           sub_sub_menu_bg_img_url, 
           sub_sub_menu_hl_img_url,
           element_height,
           nvl(element_width, 0) + 7 as element_width,
           orientation
    from   pdm_menus
    where  menu_id = :menu_id" 

if {$orientation != "horizontal"} {
    set body_css "BODY { margin-left: $element_width }"
} else {
    set body_css ""
}

doc_return  200 text/html "
$body_css

.mainmenufont { 
    $main_menu_font_style
}
.submenufont {
    $sub_menu_font_style
}

.subsubmenufont {
    $sub_sub_menu_font_style
}

.submenu {
    background-image: url(\"$sub_menu_bg_img_url\");
    margin-left: 0;
    left: 0;
    padding: 0;
    border-width: 0;
}

.submenuhl {
    background-image: url(\"$sub_menu_hl_img_url\");
    margin-left: 0;
    left: 0;
    padding: 0;
    border-width: 0;
}
.subsubmenu {
    background-image: url(\"$sub_sub_menu_bg_img_url\");
    margin-left: 0;
    left: 0;
    padding: 0;
    border-width: 0;
}

.subsubmenuhl {
    background-image: url(\"$sub_sub_menu_hl_img_url\");
    margin-left: 0;
    left: 0;
    padding: 0;
    border-width: 0;
}

.mainmenu {
    background-image: url(\"$main_menu_bg_img_url\");
    margin-left: 0;
    left: 0;
    padding: 0;
    border-width: 0;
}

.mainmenuhl {
    background-image: url(\"$main_menu_hl_img_url\");
    margin-left: 0;
    left: 0;
    padding: 0;
    border-width: 0;
}

"

