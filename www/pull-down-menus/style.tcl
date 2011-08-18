# /pull-down-menus/style.tcl
#
# by aure@arsdigita.com, Feb 2000
#
# gets the navbar style parameters from the database and
# outputs a cascading style sheet

ad_page_variables {menu_id}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
    select main_menu_font_style, 
           sub_menu_font_style, 
           sub_sub_menu_font_style,
           main_menu_bg_img_url, 
           sub_menu_bg_img_url, 
           main_menu_hl_img_url, 
           sub_menu_hl_img_url,
           sub_sub_menu_bg_img_url, 
           sub_sub_menu_hl_img_url
    from   pdm_menus
    where  menu_id = $menu_id"]

set_variables_after_query

ns_return 200 text/html "
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




