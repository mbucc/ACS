# $Id: tree-view.tcl,v 3.0 2000/02/06 03:30:37 ron Exp $
set_the_usual_form_variables
# open_directories
# comma separated list of directories which are open

proc open_dirs_minus {open_dir_list dir_to_remove} {
    # Takes a list of open directories, removes any which have
    # dir_to_remove as a prefix, returns a concatenated string of
    # directories separated by commas
    
    set retlist {}
    foreach dir $open_dir_list {
	if { ![string match "${dir_to_remove}*" $dir] } {
	    lappend retlist $dir
	}
    }
    return [join $retlist ","]
}

proc open_dirs_plus {open_dir_list dir_to_add} {
    # Takes a list of open directories, adds dir_to_add,
    # and returns a concatenated string of directories separated by commas
    lappend open_dir_list $dir_to_add
    return [join $open_dir_list ","]
}

# Count up the number of slashes in path.
proc indent_level {path} {
    regsub -all {[^/]+} $path "" slashes
    return [string length $slashes]
}

proc indent_string {path} {
    set n [indent_level $path]
    set retstr ""
    for { set i 0 } { $i < $n } { incr i } {
	append retstr "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; "
    }
    return $retstr
}


# Print out a line for a directory.
# action is "close" or "open"
proc dirlink {dir path open_dirs action} {
    if { $action == "open" } {
	set href "tree-view.tcl?open_directories=[ns_urlencode [open_dirs_plus $open_dirs $path]]"
    } else {
	set href "tree-view.tcl?open_directories=[ns_urlencode [open_dirs_minus $open_dirs $path]]"
    }

    return "[indent_string $path]<img src=\"/graphics/folder.gif\"><a href=\"$href\">$dir</a><br>\n"
}


# Returns prefix, subdir, or exact depending on whether the path
# is a prefix, a subdirectory of, or an exact match of any open directory.
proc directory_display_code {path open_directories} {
    foreach dir $open_directories {
	if { [string compare $dir $path] == 0 } {
	    return "exact"
	}
    }
    foreach dir $open_directories {
	if { [string match "${path}/*" $dir] } {
	    return "prefix"
	}
    }
    foreach dir $open_directories {
	if { [regexp "$dir/\[^/\]+\$" $path] } {
	    return "subdir"
	}
    }
    return "none"
}

set open_dirs [split $open_directories ","]

set db [ns_db gethandle]

set selection [ns_db select $db "select page_id, url_stub, page_title, accept_comments_p, accept_links_p from static_pages order by url_stub"]

ReturnHeaders

# set seen [ns_set new]
set seen() ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    set path_elements [split $url_stub "/"]

    # For each of the directory elements, if we haven't seen it
    # before and it should be displayed, write out a line for it.
    set curpath ""
    set n [expr [llength $path_elements] - 1]
    set display_code ""

    for {set i 1} {$i < $n} {incr i} {
	set dir [lindex $path_elements $i]
	set newpath "$curpath/$dir"

	# set display_code [ns_set get $seen $newpath]
	if { [info exists seen($newpath)] } {
	    set display_code $seen($newpath)
	} else { 
	    set display_code [directory_display_code $newpath $open_dirs]

	    # ns_set put $seen $newpath $display_code
	    set seen($newpath) $display_code

	    if { $display_code == "prefix" || $display_code == "exact" } {
		# close it if clicked.
		ns_write "[dirlink $dir $newpath $open_dirs close]\n"
 	    } elseif { $display_code == "subdir" || $i == 1 } {
		# display it.
		ns_write "[dirlink $dir $newpath $open_dirs open]\n"
	    } else {
		break
	    }
	}

	set curpath $newpath
    }
    
    if { $display_code == "exact" || $n == 1 } {
	set file [lindex $path_elements $n]
	ns_write "[indent_string $url_stub]$file \"$page_title\"<br>\n"
    }
}