ad_library {
    An API for creating pull down menus.

    @creation-date 1 Feb 2000
    @author Aure Prochazka [aure@arsdigita.com]
    @cvs-id pull-down-menu-defs.tcl,v 3.9.2.6 2000/07/19 09:26:15 seb Exp
}

proc ad_admin_pdm {} {
    return [ad_pdm "admin"]
}

# Updated to new db api by bquinn, 2000-07-07

# Memoized by jsc, 2000-06-08
# db arg is ignored, now that it is being memoized.

# Added memoize_flush check, randyb, 2000-06-09

proc_doc ad_pdm {{menu_key ""} {x_offset ""} {y_offset ""} {flush_p "f"}} {Returns a
script that sets up the javascript parameters for a particular menu
bar. } {

    set user_id [ad_verify_and_get_user_id]

    if { $user_id } {
	set registered_p 1
    } {
	set registered_p 0
    }

    #  Make sure that double quotes in menu_key don't make problems
    regsub -all {"} $menu_key {\"} menu_key

    if {$flush_p == "t"}  {
	util_memoize_flush "ad_pdm_helper \"$menu_key\" \"$x_offset\" \"$y_offset\" $registered_p"
    }

    return [util_memoize "ad_pdm_helper \"$menu_key\" \"$x_offset\" \"$y_offset\" $registered_p"]
}

proc ad_pdm_helper {menu_key x_offset y_offset registered_p} {
    if [empty_string_p $menu_key] {
	set default_p "t"
	set menu_id [db_string default_menu_id "select menu_id from pdm_menus
	where default_p = :default_p" ]
    } else {
	set menu_id [db_string menu_id_by_menu_key "select menu_id from pdm_menus
	where menu_key = :menu_key" ]
    }

    set offsets ""
    if [empty_string_p $x_offset] {
	append offsets "x_offset, "
    }
    if [empty_string_p $y_offset] {
	append offsets "y_offset, "
    }

    db_0or1row menu_config {
        select x_offset as new_x_offset,
	       y_offset as new_y_offset,
               main_menu_font_style,
	       sub_menu_font_style,
	       main_menu_bg_color,
	       main_menu_bg_img_url,
	       main_menu_hl_color,
	       main_menu_hl_img_url,
	       sub_menu_bg_color,
	       sub_menu_bg_img_url,
	       sub_menu_hl_color,
	       sub_menu_hl_img_url,
	       sub_sub_menu_bg_color,
	       sub_sub_menu_bg_img_url,
	       sub_sub_menu_hl_color,
	       sub_sub_menu_hl_img_url,
	       element_height,
	       element_width,
	       orientation
        from pdm_menus
        where menu_id = :menu_id
    }

    if [empty_string_p $x_offset] {
	set x_offset $new_x_offset
    }
    if [empty_string_p $y_offset] {
	set y_offset $new_y_offset
    }

    set script "
    <script>
    var isIE,isNN;
    function checkBrow() {
	var vers = parseInt(navigator.appVersion);
	var agt = navigator.userAgent.toLowerCase();
	if (agt.indexOf(\"win\")!=-1) {
	    var plat = \"pc\";
	} else if (agt.indexOf(\"mac\")!=-1) {
	    var plat = \"mac\";
	}
    }

    checkBrow();
    </script>
    <link rel=stylesheet href=\"/pull-down-menus/style?menu_id=$menu_id\"
    type=\"text/css\">
    <script src=\"/pull-down-menus/standard.js\"></script>
    <script src=\"/pull-down-menus/pdm.js\"></script>
    <script>
    var click_to_open_menu_p = [ad_parameter "ClickToOpenP" "pdm" 0];

    if (click_to_open_menu_p) {
	var hoverActive = false;
    } else {
	var hoverActive = true;
    }

    var y_offset = $y_offset;
    var x_offset = $x_offset;
    var main_menu_bg_color = '$main_menu_bg_color';
    var main_menu_hl_color = '$main_menu_hl_color';
    var main_menu_bg_img_url = '$main_menu_bg_img_url';
    var main_menu_hl_img_url = '$main_menu_hl_img_url';
    var sub_menu_bg_color = '$sub_menu_bg_color';
    var sub_menu_hl_color = '$sub_menu_hl_color';
    var sub_menu_bg_img_url = '$sub_menu_bg_img_url';
    var sub_menu_hl_img_url = '$sub_menu_hl_img_url';
    var sub_sub_menu_bg_color = '$sub_sub_menu_bg_color';
    var sub_sub_menu_hl_color = '$sub_sub_menu_hl_color';
    var sub_sub_menu_bg_img_url = '$sub_sub_menu_bg_img_url';
    var sub_sub_menu_hl_img_url = '$sub_sub_menu_hl_img_url';

    var element_height = $element_height;
    var element_width = $element_width;
    var orientation = '$orientation';
    "

    # Are we creating menus for an anonymous or registered user?

    if {!$registered_p} {
	set constraint "and requires_registration_p = 'f'"
    } else {
	set constraint ""
    }


    set sql_qry "
    select p1.item_id,
	   p1.label,
	   p1.sort_key,
	   nvl(p1.url,'#') as url,
	   (select count(*)
	    from pdm_menu_items p2
	    where p2.sort_key like p1.sort_key||'__') as number_of_children,
	   (select p3.label
	    from pdm_menu_items p3
	    where menu_id = :menu_id
	    and p3.sort_key = substr(p1.sort_key,1, length(p1.sort_key)-2)) as parent_label
    from pdm_menu_items p1
    where menu_id = :menu_id $constraint
    order by p1.sort_key"

    append script "if (isIE || isNN) \{ \n"

    set current_url [ns_conn url]
    set open_parent_label ""
    db_foreach menu_build $sql_qry {
	# Get rid of everything that's not javascript friendly
	
	regsub -all {[^A-z0-9]} $label "" js_label
	regsub -all {[^A-z0-9]} $parent_label "" parent_label

	if {$current_url == $url || $current_url == "${url}index.tcl" || $current_url == "${url}index.html" || $current_url == "${url}index"} {
	    set opened_p "true"
	} else {
	    set opened_p "false"
	}

	if {[empty_string_p $parent_label]} {

	    append script "\n
	    var $js_label = new NavBarItem(\"$label\",\"$url\", true, $opened_p);"
	} elseif {$number_of_children > 0} {
	    append script "\n
	    var $js_label = $parent_label.cascade.addMember(\"${label} ...\",\"$url\",true);"
	} else {
	    append script "
	    $parent_label.cascade.addMember(\"$label\",\"$url\",false);"
	}
    } 

    append script "\n \}
    if (isIE || isNN) MakeNavLayers();
    </script>
    "

    return $script
}

proc_doc ad_pdm_spacer { {menu_key ""} } {
    Returns html to precede the page content,
    leaving room for the pull-down menu
} {

    if [empty_string_p $menu_key] {
	set constraint "where default_p = 't'"
    } else {
	set constraint "where menu_key = :menu_key"
    }
    
    db_0or1row "pdm_spacer" "
        select element_height, element_width, orientation
        from pdm_menus
        $constraint" 

    if {$orientation == "horizontal"} {
	set spacer "<img src=\"/graphics/graphing-package/transparent-dot.gif\" height=$element_height width=$element_width><br>"
    } else {
	set spacer ""
    }

    return $spacer
}

# -----------------------------------------------------------------------------

# indents a submenu by a specified amount

proc pdm_indentation {depth} {
    set indentation ""
    for {set i 0} {$i <= $depth} {incr i} {
	append indentation "&nbsp; &nbsp; "
    }
    return $indentation
}

# is this the last child in a submenu?

proc pdm_last_child_p {sort_key_list sort_key} {
    set key_length [string length $sort_key]
    set key_next [format "%0${key_length}d" [expr [string trimleft
    $sort_key 0]+1]]

# the given sort_key is the last child if the search comes back
# with -1 (no such key in the list)

    return [expr [lsearch $sort_key_list $key_next] == -1]
}
