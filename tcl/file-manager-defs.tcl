# /tcl/file-manager-defs.tcl

ad_library {

    Private tcl definitions for the file manager

    @author  Ron Henderson (ron@arsdigita.com)
    @created Fri May 26 05:32:59 2000
    @cvs-id  file-manager-defs.tcl,v 3.2.2.4 2000/11/21 00:29:03 ron Exp
}

proc fm_pageroot_relative_path {path} {
    regexp "[ns_info pageroot](.+)" $path match local
    return $local
}

proc fm_acs_root_relative_path {path} {
    regexp "[acs_root_dir](.+)" $path match relative
    return $relative
}

# Returns 1 if $path is a valid file name (no spaces and no leading /'s)

proc fm_valid_filename_p { path } { 
    if [regexp {[ /&]} $path] {
	return 0
    } else {
	return 1
    }
}

# Set up a context bar that will break out of the frames

proc fm_admin_context_bar {} {
    regsub -all "href" [ad_admin_context_bar "File Manager"] "target=_top href" context_bar
    return $context_bar
}

# Turn the local path into a linked list of directories

proc fm_linked_path {path_full} {

    # Grab the path relative to the pageroot and create a linked list
    # of path components for the top of the directory listing

    set pageroot [ns_info pageroot]

    regexp "$pageroot/(.+)" $path_full match path

    set local ""
    set path_list   [list]
    set path_orig   [file split $path]
    set path_length [expr [llength $path_orig]-1]

    for { set i 0 } { $i < $path_length } { incr i } {
	set dir [lindex $path_orig $i]
	lappend path_list "<a target=list href=file-list?path=[file join $pageroot $local $dir]>$dir</a>"
	set local [file join $local $dir]
    }

    lappend path_list [file tail $path]
    return [join $path_list " / "]
}

# Checks for any function execution in an adp page

proc fm_adp_function_p {adp_page} {
    if {[ad_parameter BlockUserADPFunctionsP ADP 1] != 1} {
	return 0
    }
    if {[regexp {<%[^=](.*?)%>} $adp_page match function]} {
	set user_id [ad_get_user_id]
	ns_log warning "User: $user_id tried to include \n$function\nin an adp page"
	return 1
    } elseif {[regexp {<%=.*?(\[.*?)%>} $adp_page match function]} {
	set user_id [ad_get_user_id]
	ns_log warning "User: $user_id tried to include \n$function\nin an adp page"
	return 1
    } else {
	return 0
    }
}

ad_proc fm_managed_directories {} {

    Returns a list of directories relative to www that will be
    accessible via file-manager.  All subdirectories are also managed
    (unless they're in the Ignore list).  This is a wrapper for the
    ManagedDirectories parameter that return a list of all directories
    if no explicit list is given.

} {
    set manage [ad_parameter "ManagedDirectories" "file-manager" ""]

    if ![empty_string_p $manage] {
	return [split $manage ","]
    } else {
	set files  [list]
	set ignore [split [ad_parameter Ignore file-manager "admin"] ","]
	foreach file [lsort [glob "[acs_root_dir]/www/*"]] {
	    set tail [file tail $file]
	    if {[lsearch $ignore $tail] != -1} {
		continue
	    }
	    if [file isdirectory $file] {
		lappend files $tail
	    }
	}
	return $files
    }
}