# pull-down-menu-defs.tcl
#
# Author: aure@arsdigita.com, February 2000
#
# $Id: pull-down-menu-defs.tcl,v 3.2.2.3 2000/03/17 17:44:44 aure Exp $
# -----------------------------------------------------------------------------

# wrapper to call ad_pdm with "admin" as the key

proc ad_admin_pdm {} {
    return [ad_pdm "admin"]
}

proc_doc ad_pdm {{menu_key ""} {x_offset ""} {y_offset ""} {db ""}} {Returns a
script that sets up the javascript parameters for a particular menu
bar} {

    set user_id [ad_verify_and_get_user_id]
    
    if [empty_string_p $db] {
	set db [ns_db gethandle subquery]
	set release_db_handle_p 1
    } else {
	set release_db_handle_p 0
    }

    if [empty_string_p $menu_key] {
	set menu_id [database_to_tcl_string $db "select menu_id from pdm_menus where default_p = 't'"]
    } else {
	set menu_id [database_to_tcl_string $db  "select menu_id from pdm_menus where menu_key = '$menu_key'"]
    }
   
    set offsets ""
    if [empty_string_p $x_offset] {
	append offsets "x_offset, "
    }
    if [empty_string_p $y_offset] {
	append offsets "y_offset, "
    }

    set selection [ns_db 0or1row $db "
        select $offsets
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
        from   pdm_menus 
        where  menu_id = $menu_id"]
    set_variables_after_query

    set script "
    <script>
    var isIE,isNN; 
    function checkBrow() {
	var vers = parseInt(navigator.appVersion);
	var agt  = navigator.userAgent.toLowerCase();
	if (agt.indexOf(\"win\")!=-1) {
	    var plat = \"pc\";
	} else if (agt.indexOf(\"mac\")!=-1) {
	    var plat = \"mac\";
	}
    }
    
    checkBrow();
    </script>
    <link rel=stylesheet href=\"/pull-down-menus/style?menu_id=$menu_id\" type=\"text/css\">
    <script src=\"/pull-down-menus/standard.js\"></script>
    <script src=\"/pull-down-menus/pdm.js\"></script>
    <script>
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
    var element_width  = $element_width;
    var orientation    = '$orientation';
    "

    # Are we creating menus for an anonymous or registered user?

    if {$user_id == 0} {
	set constraint "and requires_registration_p = 'f'"
    } else {
	set constraint ""
    }

    set selection [ns_db select $db "
    select p1.item_id, 
           p1.label, 
           p1.sort_key, 
           nvl(p1.url,'#') as url,
           (select count(*)
            from   pdm_menu_items p2
            where  p2.sort_key like substr(p1.sort_key,0,length(p1.sort_key))||'__') as number_of_children,
           (select p3.label
            from   pdm_menu_items p3
            where  menu_id = $menu_id
            and    p3.sort_key like substr(p1.sort_key,0, length(p1.sort_key)-2)) as parent_label
    from   pdm_menu_items p1 
    where  menu_id = $menu_id $constraint
    order by p1.sort_key"]
    
    append script "if (isIE || isNN) \{ \n"
    
    set current_url [ns_conn url]
    set open_parent_label ""
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

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
	    var $js_label =  $parent_label.cascade.addMember(\"${label} ...\",\"$url\",true);" 
	} else {
	    append script "
	    $parent_label.cascade.addMember(\"$label\",\"$url\",false);"
	}
    }


    append script "\n    \}
    if (isIE || isNN) MakeNavLayers();
    </script>
    "

    if { $release_db_handle_p == 1 } {
	ns_db releasehandle $db
    }
    return $script
}

proc_doc ad_pdm_spacer {{menu_key ""} {db ""}} {Returns html to precede the page content,
leaving room for the pull-down menu} {
    
    if [empty_string_p $db] {
	set db [ns_db gethandle subquery]
	set release_db_handle_p 1
    } else {
	set release_db_handle_p 0
    }

    if [empty_string_p $menu_key] {
	set constraint "where default_p = 't'"
    } else {
	set constraint "where menu_key = '$menu_key'"
    }
    
    set selection [ns_db 0or1row $db "
        select element_height, element_width, orientation
        from   pdm_menus 
        $constraint"]
    set_variables_after_query
  
    if {$orientation == "horizontal"} {
	set spacer "<img src=\"/graphics/graphing-package/transparent-dot.gif\" height=$element_height width=$element_width><br>"
    } else {
	set spacer "<table cellpadding=0 cellspacing=0 border=0>
	            <tr>
	            <td width=$element_width>&nbsp;</td>
	            <td width=10></td>
                    <td>"
    }

    if { $release_db_handle_p == 1 } {
	ns_db releasehandle $db
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
    set key_next   [format "%0${key_length}d" [expr [string trimleft $sort_key 0]+1]]

    # the given sort_key is the last child if the search comes back
    # with -1 (no such key in the list)

    return [expr [lsearch $sort_key_list $key_next] == -1]
}


