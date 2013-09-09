ad_library {

    Routines necessary to load package code.

    @creation-date 26 May 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id 20-apm-load-procs.tcl,v 1.2.2.3 2000/07/14 15:47:16 bquinn Exp
}


proc_doc empty_string_p {query_string} {
    returns 1 if a string is empty; this is better than using == because it won't fail on long strings of numbers
} {
    if { [string compare $query_string ""] == 0 } {
	return 1
    } else {
	return 0
    }
}

proc_doc acs_root_dir {} { 
    Returns the path root for the ACS installation. 
} {
    return [nsv_get acs_properties root_directory]
}

proc_doc acs_package_root_dir { package } { 
    Returns the path root for a particular package within the ACS installation. 
} {
    return "[acs_root_dir]/packages/$package"
}

proc_doc ad_make_relative_path { path } { 
    Returns the relative path corresponding to absolute path $path. 
} {
    set root_length [string length [acs_root_dir]]
    if { ![string compare [acs_root_dir] [string range $path 0 [expr { $root_length - 1 }]]] } {
	return [string range $path [expr { $root_length + 1 }] [string length $path]]
    }
    error "$path is not under the path root ([acs_root_dir])"
}

proc_doc apm_source { __file } {
    Sources $__file in a clean environment, returning 1 if successful or 0 if not.
} {
    if { ![file exists $__file] } {
	ns_log "Error" "Unable to source $__file: file does not exist."
	return 0
    }

    # Actually do the source.
    if { [catch { source $__file }] } {
	global errorInfo
	ns_log "Error" "Error sourcing $__file:\n$errorInfo"
	return 0
    }

    return 1
}

proc_doc apm_first_time_loading_p {} { 
    Returns 1 if this is a -procs.tcl file's first time loading, or 0 otherwise. 
} {
    global apm_first_time_loading_p
    return [info exists apm_first_time_loading_p]
}



