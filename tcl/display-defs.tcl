# $Id: display-defs.tcl,v 3.0 2000/02/06 03:13:09 ron Exp $
# File:   /tcl/css-defs.tcl
# Date:   12/27/99
# Author: Tarik Alatovic
# Email:  tarik@arsdigita.com
#
# Purpose: utility functions used for css module

proc_doc css_generate_complete_css { db } "assumes scope is set in the callers enironment. if scope=user it assumes user_id is set in callers environment and if scope=group it assumes that group_id is set in callers environment. it returns generate css string from the css_complete table matching the provided scope" {

    upvar scope scope 

    if { $scope=="group" } {
	upvar group_id group_id
    }
    if { $scope=="user" } {
	upvar user_id user_id
    }

    set selection [ns_db select $db "
    select selector, property, value
    from css_complete
    where [ad_scope_sql]"]
    
    set_variables_after_query
    
    set counter 0
    set last_selector ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	
	if { [string compare $selector $last_selector]!=0 } {
	    if { $counter > 0 } {
		append css " \}\n" 
	    }
	    append css "$selector \{ "
	} else {
	    append css "; "
	}
	
	append css "$property: $value"
	
	incr counter
	set last_selector $selector
    }
    
    if { $counter > 0 } {
	append css " \}"
    } else {
	# no css values supplied
	set css ""
    }

    return $css
}


proc_doc css_html_color_name_p { font_name } "returns 1 if font_name is one of the html defined font names and returns 0 otherwise" {
    if { [lsearch -exact { white silver gray maroon green navy purple olive teal black red lime blue magenta yellow cyan} $font_name] != -1 } {
	return 1
    } else {
	return 0
    }
}

# this procedure takes a list of variable names and returns list of existing variable values
proc css_list_existing args {
    set num_args [llength $args]
    
    set result_list [list]
    for {set i 0} {$i < $num_args} {incr i} {
	set element [lindex $args $i]
	if { [eval uplevel {info exists $element}] } {
	    upvar $element temp_var
	    lappend result_list $temp_var
	}
    }
    return $result_list
}
