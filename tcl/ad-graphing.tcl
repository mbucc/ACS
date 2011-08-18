# $Id: ad-graphing.tcl,v 3.0 2000/02/06 03:12:26 ron Exp $
## Make sure you have the latest version of utilities.tcl running on
## your server, otherwise ad_proc doesn't exist

ad_proc gr_sideways_bar_chart { {-legend "" -bar_color_list "" -display_values_p "f" -display_scale_p "t" -default_drilldown_url "" -non_percent_values_p "f" -min_left_column_width "1" -bar_height "15" -subcategory_spacing "7" -compare_non_percents_across_categories "f" -left_heading "" -right_heading "" -replace_null_subcategory_with_none_p "f"} subcategory_category_and_value_list } "Read <a href=\"http://software.arsdigita.com/www/doc/graphing.html\">http://software.arsdigita.com/www/doc/graphing.html</a>" {

    if { $bar_color_list == "" } {
	set bar_color_list [list blue dark-green purple red black orange medium-blue]
    }

    if { $non_percent_values_p == "t" } {
	# If the values aren't percentages, I'll turn them into percentages just for the bar display.
	
	if { $compare_non_percents_across_categories == "f" } {
	    # The highest number in a category will correspond to a percentage of 75%, and the others will 
	    # be relative to it.
	    
	    set prev_category "initial_condition"
	    set temp_values_list ""
	    foreach subcategory_category_and_value $subcategory_category_and_value_list {
		set category [lindex $subcategory_category_and_value 1]
		set values [lindex $subcategory_category_and_value 2]
		if { $prev_category != "initial_condition" && $category != $prev_category } {
		    lappend just_categories_and_values_list [list $prev_category $temp_values_list]
		    set temp_values_list ""
		}
		set temp_values_list [concat $temp_values_list $values]
		set prev_category $category
	    }
	    lappend just_categories_and_values_list [list $prev_category $temp_values_list]
	    
	    foreach category_values_map $just_categories_and_values_list {
		
		set values_list [gr_list_with_non_numeric_elements_replaced_by_zeroes [lindex $category_values_map 1]]
		set sorted_values_list [lsort -real $values_list]
		set max_value_for_this_category [lindex $sorted_values_list [expr [llength $sorted_values_list] -1 ] ]
		set max_value([lindex $category_values_map 0]) "$max_value_for_this_category"
	    }
	} else {
	    # The highest number in all categories will correspond to a percentage of 75%, and the others
	    # will be relative to it.
	    set temp_values_list ""
	    foreach subcategory_category_and_value $subcategory_category_and_value_list {
		set values [lindex $subcategory_category_and_value 2]
		set temp_values_list [concat $temp_values_list $values]
	    }
	    set values_list [gr_list_with_non_numeric_elements_replaced_by_zeroes $temp_values_list]
	    set sorted_values_list [lsort -real -decreasing $values_list]
	    set max_value_of_all_values [lindex $sorted_values_list 0]
	}
    }

    set to_return ""

    if { $legend != "" } {
	set legend_counter 0
	append to_return "<table border=1 cellspacing=0 cellpadding=5><tr><td>"
	foreach key $legend {
	    append to_return "<img width=15 height=15 src=\"/graphics/graphing-package/[lindex $bar_color_list [expr round(fmod($legend_counter,[llength $bar_color_list]))]]-dot.gif\"> &nbsp;[gr_font black 3]$key<br clear=all>"
	    incr legend_counter
	}
	append to_return "</td></tr></table><p>"
    }

    append to_return "<table border=0 cellspacing=0 cellpadding=0>"

    if { [string compare $left_heading ""] != 0 || [string compare $right_heading ""] != 0 } {
	append to_return "<tr><td>$left_heading</td><td></td><td>$right_heading</td></tr>
	<tr><td><img width=1 height=5 src=\"/graphics/graphing-package/white-dot.gif\"></td><td></td><td></td></tr>\n"
    }

    set prev_category "initial_condition"

    foreach subcategory_category_and_value $subcategory_category_and_value_list {
	set subcategory [lindex $subcategory_category_and_value 0]
	set category [lindex $subcategory_category_and_value 1]
	set values [lindex $subcategory_category_and_value 2]
	set drilldown_url [lindex $subcategory_category_and_value 3]
	# values is a list

	if { $category != $prev_category } {
	    set prev_category $category
	    append to_return "<tr><td><img width=$min_left_column_width height=10 src=\"/graphics/graphing-package/white-dot.gif\"><br clear=all>[gr_font black 4][lindex $subcategory_category_and_value 1]</font></td>"
	    if { $display_scale_p == "t" } {
		append to_return "<td align=right><img width=10 height=15 src=\"/graphics/graphing-package/scale-left.gif\"><br clear=all><img width=1 height=3 src=\"/graphics/graphing-package/white-dot.gif\"></td><td><img width=320 height=15 src=\"/graphics/graphing-package/scale-main.gif\"><br clear=all><img width=1 height=3 src=\"/graphics/graphing-package/white-dot.gif\"></td></tr>"
	    } else {
		append to_return "<td><img width=10 height=15 src=\"/graphics/graphing-package/white-dot.gif\"></td><td> </td></tr>"
	    }
	}

	if { $replace_null_subcategory_with_none_p == "t" } {
	    append to_return "<tr><td>[gr_font][gr_none_if_null $subcategory]</font></td><td width=10> </td><td>"
	} else {
	    append to_return "<tr><td>[gr_font]$subcategory</font></td><td width=10> </td><td>"
	}


	# value_counter is to determine bar_color
	set value_counter 0
	foreach value $values {

	    if { $non_percent_values_p == "t" } {
		if { $compare_non_percents_across_categories == "f" } {
		    if { $max_value($category) != 0 && ![regexp "\[^0-9.% \]" $value] && [string compare $value ""] != 0 } {
			set bar_length [expr 75*$value/$max_value($category)]
		    } else {
			set bar_length 0
		    }
		} else {
		    if { $max_value_of_all_values != 0 && ![regexp "\[^0-9.% \]" $value] && [string compare $value ""] != 0 } {
			set bar_length [expr 75*$value/$max_value_of_all_values]
		    } else {
			set bar_length 0
		    }
		}
	    } else {
		set bar_length [gr_remove_percent $value]
	    }
	    
	    set bar_color [lindex $bar_color_list [expr round(fmod($value_counter,[llength $bar_color_list]))]]

	    if { [regexp "\[^0-9.% \]" $value] || [string compare $value ""] == 0 } {
		set img_width 1
	    } elseif { $bar_length != 0 } {
		set img_width [expr round(3 * $bar_length)]
	    } else {
		set img_width 1
	    }
	    append to_return "<img width=$img_width height=$bar_height src=\"/graphics/graphing-package/$bar_color-dot.gif\">"

	    if { [empty_string_p $drilldown_url] } {
		set drilldown_url [subst $default_drilldown_url]
	    }
	    if { ![empty_string_p $drilldown_url] } {
		append to_return " [gr_font [hex_color $bar_color] 1]<a href=\"$drilldown_url\">$value</a></font>"
	    } else {
		append to_return " [gr_font [hex_color $bar_color] 1]$value</font>"
	    }

	    append to_return "<br clear=all>\n"
	    incr value_counter
	} 

	append to_return "<img width=1 height=$subcategory_spacing src=\"/graphics/graphing-package/white-dot.gif\"></td></tr>"



    } ; #  end  foreach subcategory_category_and_value $subcategory_category_and_value_list

    append to_return "</table>"
    return $to_return
}

proc hex_color {color} {
    switch $color {
	"red" {set hex_color "ff0000"}
	"blue" {set hex_color "0000ff"}
	"yellow" {set hex_color "ffff00"}
	"black" {set hex_color "000000"}
	"white" {set hex_color "ffffff"}
	"dark-green" {set hex_color "009900"}
	"aquamarine" {set hex_color "00ffff"}
	"purple" {set hex_color "660099"}
	"orange" {set hex_color "ff6600"}
	"medium-blue" {set hex_color "0099ff"}
	"magenta" {set hex_color "ff00ff"}
	"muted-green" {set hex_color "669966"}
	"muted-yellow" {set hex_color "999966"}
	"muted-red" {set hex_color "996666"}
	"muted-magenta" {set hex_color "996699"}
	"muted-blue" {set hex_color "666699"}
	"muted-aquamarine" {set hex_color "669999"}
    }
}


proc gr_list_with_non_numeric_elements_replaced_by_zeroes { the_list } {
    set new_list ""
    foreach element $the_list {
	if { [regexp "\[^0-9.% \]" $element] || [string compare $element ""] == 0 }  {
	    lappend new_list 0
	} else {
	    lappend new_list $element
	}
    }
    return $new_list
}

proc gr_none_if_null { the_value } {
    if { [string compare $the_value ""] == 0 } {
	return "\[none\]"
    } else {
	return $the_value
    }
}

proc gr_remove_percent { the_value } {
    regsub -all "%" $the_value "" new_value
    return $new_value
}

proc gr_font { {color black} {size 3} } {
    return "<font face=arial size=$size color=$color>"
}

