# /tcl/vc-defs.tcl

ad_library {
    version-control library

    @author  Ron Henderson (ron@arsdigita.com)
    @created December 1999
    @cvs-id  vc-defs.tcl,v 3.9.2.3 2000/08/03 21:19:19 ron Exp
}

# This file provides an API for talking to the version control system
# for the site.  It is hard-coded for the Concurrent Versions System
# (CVS).  There are procs to fetch various types of status information
# and procs to execute certain version control operations on the
# underlying files.
#
# All procs take absolute path names as arguments.
#
# If you need detailed information, you can ask vc to parse the output
# of the CVS log and status commands to fill out the vc_file_props
# array.  This sets the following keys:
#
#       file          file that we're looking at
#       path          absolute path of the file
#       root          contents of CVS/Root 
#       repository    contents of CVS/Repository
#       master        name of the version control file
#       revision      current revision
#       date          date this revision was committed
#       author        who committed it
#       state         cvs state of the file  (Exp, Stab, Rel)
#       status        output of the cvs status command
#       log           output of the cvs log command
#
# NSV arrays used by the version control system to cache file properties:
#
# vc_status_cache($path)
#
#    A cached result from vc_fetch_status (of the form [list $mtime
#    $status]) containing the result of 'cvs status $path'.
#
# vc_summary_cache($path)
#
#    A cached result from vc_fetch_summary (of the form [list $mtime
#    $summary]) containing the line from CVS/Entries for $path.
#
# vc_log_cache($path)
#
#    A cached result from vc_fetch_log (of the form [list $mtime
#    $log]) containing the result of 'cvs log $path'
#
# vc-defs.tcl,v 3.9.2.3 2000/08/03 21:19:19 ron Exp
# -----------------------------------------------------------------------------

proc_doc vc_path_relative { path } {

    Returns the component of path relative to [acs_root_dir].
    If path does not begin with [acs_root_dir] it is returned
    unchanged. 

} {
    set root [acs_root_dir]

    # verify that path starts with $root
    if { [string first $root $path] == 0 } {
	# it does, so trim out the leading part
	set path [string range $path [expr { [string length $root] + 1 }] end]
    }

    return $path
}

# Fetches the name of the repository that path was checked out of
# (relative to the CVSROOT, if -relative is specified).
# If path is not specified, looks under acs_root_dir.

ad_proc vc_fetch_repository {
    { -relative 0 }
    { path "" }
} {} {
    if { [empty_string_p $path] } {
	set dirname [acs_root_dir]
    } else {
	set dirname [file dirname $path]
    }
    set cvs_repository "$dirname/CVS/Repository"
    if {[file exists $cvs_repository]} {
	set repository [gets [set fp [open $cvs_repository r]]]
	close $fp
    } else {
	set repository ""
    }
    if { $relative } {
	set root [vc_fetch_root $path]
	if { [string first $root $repository] == 0 } {
	    # $repository begins with $root; trim off the $root part
	    set repository [string range $repository [expr { [string length $root] + 1 }] end]
	}
    }

    return $repository
}

proc_doc vc_fetch_root { { path "" } } {

    Fetches the CVSROOT associated with path. If path is not specified,
    looks under acs_root_dir.  This is always overridden by the CVSROOT
    parameter in the ini file.

} {

    # Try the system default
    set root [ad_parameter CVSROOT vc]

    # If not defined we go to the fallback methods
    if [empty_string_p $root] {
	
	if { [empty_string_p $path] } {
	    set cvs_root "[acs_root_dir]/CVS/Root"
	} else {
	    set cvs_root "[file dirname $path]/CVS/Root"
	}
	if {[file exists $root]} {
	    set root [gets [set fp [open $cvs_root r]]]
	    close $fp
	}
    }

    return $root
}

# Fetches the status report for a file

proc_doc vc_fetch_status { path } {

    Returns the CVS status report for a file, caching it based on mtime
    if it exists.

} {
    if { [nsv_exists vc_status_cache $path] }  {
	set status_info [nsv_get vc_status_cache $path]
	# If the mtime hasn't changed, return the cached status.
	if { [lindex $status_info 0]  == [file mtime $path] } {
	    return [lindex $status_info 1]
	}
	# mtime has changed, so kill the cache entry
	nsv_unset vc_status_cache $path
    }

    # Get the status report.

    if {[catch {
	
	set status [vc_exec "status [vc_path_relative $path]"]
	
    } errmsg]} {
	ns_log Error "vc_fetch_status: $errmsg"
	set status ""
    }

    if ![empty_string_p $status] {
	nsv_set vc_status_cache $path [list [file mtime $path] $status]
    }

    return $status
}

proc_doc vc_fetch_log { path } {

    Fetches the change log for a file

} {

    if { [nsv_exists vc_log_cache $path] } {
	set info [nsv_get vc_log_cache $path]
	if { [lindex $info 0] == [file mtime $path] } {
	    return [lindex $info 1]
	} else {
	    # mtime has changed, kill the cache
	    nsv_unset vc_log_cache $path
	}
    }

    # Get the log information and cache it

    if {[catch {

	set log [vc_exec "log [vc_path_relative $path]"]

    } errmsg]} {
	ns_log Error "vc_fetch_log: $errmsg"
	set log ""
    }

    if ![empty_string_p $log] {
	nsv_set vc_log_cache $path [list [file mtime $path] $log]
    }

    return $log
}

# Fetches the summary report for a file

proc_doc vc_fetch_summary { path } {

    Returns the CVS summary report for a file, caching it based on
    mtime.

} {
    if { [nsv_exists vc_summary_cache $path] }  {
	set info [nsv_get vc_summary_cache $path]
	if { [lindex $info 0] == [file mtime $path] } {
	    return [lindex $info 1]
	} else {
	    # mtime has changed, kill the cache
	    nsv_unset vc_summary_cache $path
	}
    }

    # Get the summary information and cache it.

    set summary  ""
    set entries "[file dirname $path]/CVS/Entries"
    set tail    "[file tail $path]"
    if [file exists $entries] {
	set summary [read [set fp [open $entries r]]]
	close $fp
	if [regexp "/$tail/(\[^\n\]+)" $summary match info] {
	    set summary "/$tail/$info"
	    nsv_set vc_summary_cache $path [list [file mtime $path] $summary]
	}
    }

    return $summary
}

proc_doc vc_fetch_date { path } {
    
    Returns the commit time for a file, or the empty string if no
    version control information is available.

} {
    return [lindex [split [vc_fetch_summary $path] "/"] 3]
}

proc_doc vc_fetch_revision { path } {

    Returns the revision number for a file, or the empty string if no
    version control information is available.  

} {
    return [lindex [split [vc_fetch_summary $path] "/"] 2]
}

# -----------------------------------------------------------------------------
# Parsers for various CVS output data
# -----------------------------------------------------------------------------

# Parse the output of 'cvs status'

proc vc_parse_cvs_status { status } {
    global vc_file_props

    set file       ""
    set revision   ""
    set master     ""

    regexp {File: ([^ ]+)} $status match file     
    regexp "Working revision:\[ \]*(\[^ a-zA-Z\]+)" $status match revision
    regexp "Repository revision:\[ \]*(\[^ a-zA-Z\]+)(\[^\n\]+)" $status match tmp master

    set vc_file_props(file)     [string trim $file]
    set vc_file_props(revision) [string trim $revision]
    set vc_file_props(master)   [string trim $master]

    return
}

# Parse the output of 'cvs log' for the current revision (must be set
# by a previous call to vc_parse_cvs_status)

proc vc_parse_cvs_log { log } {
    global vc_file_props

    set date   ""
    set author ""
    set state  ""
    set info   ""

    # pull out the information for the requested revision
    regexp "revision $vc_file_props(revision)\n\[^\n\]+" $log info

    regexp "date: (\[^;\]+)"   $info match date
    regexp "author: (\[^;\]+)" $info match author
    regexp "state: (\[^;\]+)"  $info match state

    set vc_file_props(date)   $date
    set vc_file_props(author) $author
    set vc_file_props(state)  $state

    return
}

# Translate the standard CVS state tags into more meaningful strings

proc vc_cvs_state_map {cvs_state} {
    switch -- $cvs_state {
	Exp     { set state "<font color=red>EXPERIMENTAL</font>" }
	Stab    { set state "<font color=green>STABLE</font>"     }
	Rel     { set state "<font color=blue>RELEASED</font>"    }
	default { set state "UNKNOWN" }
    }
    return $state
}

# -----------------------------------------------------------------------------
# Wrappers for various CVS commands
# -----------------------------------------------------------------------------

proc_doc vc_exec { cmd } {

    Wrapper for exec that sets up the correct environment for CVS and
    starts execution from [acs_root_dir].

} {
    set cvs [ad_parameter CvsPath vc "/usr/local/bin/cvs"]
    return  [exec /bin/env CVS_RSH=/usr/local/bin/ssh /bin/sh -c "cd [acs_root_dir] ; $cvs -d [vc_fetch_root] $cmd"]
}

proc_doc vc_add { path } {

    Add a file or a directory to the repository.

} { 
    if [catch { vc_exec "add [vc_path_relative $path]" } errmsg] {
	ns_log Error "vc_add: $errmsg"
	return 1
    } else {
	return 0
    }
}

proc_doc vc_commit { path message } {

    Commit a change to the repository, along with a log message.

} { 
    # Don't have to commit directories.  We do this check to make it
    # conventient to add+commit a big list of files.
    if [file isdirectory $path] {
	return
    }

    if [catch { vc_exec "commit -m \"$message\" [vc_path_relative $path]" } errmsg] {
	ns_log Error "vc_commit: $errmsg"
	return 1
    } else {
	return 0
    }
}

proc_doc vc_remove { path } {

    Remove a file from the repository.

} {
    if [file isdirectory $path] {
	return
    }

    if [catch {
	if [file exists $path] {
	    vc_exec "remove -f [vc_path_relative $path]"
	} else {
	    vc_exec "remove [vc_path_relative $path]"
	}
    } errmsg] {
	ns_log Error "vc_remove: $errmsg"
	return 1
    } else {
	return 0
    }
}

proc_doc vc_status { path } {

    Returns the output of CVS status.

} {
    return [vc_fetch_status $path]
}

proc_doc vc_log { path }  {

    Returns the output of CVS log.

} {
    return [vc_fetch_log $path]
}

proc_doc vc_update { path } {

    Updates the specified file/directory

} {
    if [catch {
	vc_exec "update [vc_path_relative $path]"
    } errmsg] {
	ns_log Error "vc_update: $errmsg"
	return 1
    } else {
	return 0
    }
}

proc_doc vc_checkout { module path } {

    Checks out a copy of the specified module to a given destination.

} {
    set cmd "checkout -d [vc_path_relative $path] $module"
    if [catch {vc_exec $cmd } errmsg] {
	ns_log Error "vc_checkout: $cmd \n\n $errmsg"
	return 1
    } else {
	return 0
    }
}

proc_doc vc_path_to_module { path } {

    Converts a path name to the correct CVS module name associated with that file. 

} {
    set root        [vc_fetch_root $path]
    set repository  [vc_fetch_repository $path]

    # Check for the existence of a : in the CVS/Root indicating a remote
    # repository.  If so set module_root to the contents of
    # CVS/Repository. 

    if [string first ":" $root] {
	set module_root $repository
    } else {
	set module_root [string range $repository [expr {[string length $root] + 1 }] end]
    }

    return [file join $module_root [file tail $path]]
}

# Initialize file properties

proc_doc vc_file_props_init { path } {

    Initialize vc_file_props for $path.

} {
    global vc_file_props
    
    set vc_file_props(path)       $path
    set vc_file_props(summary)    [vc_fetch_summary $path]
    set vc_file_props(revision)   [vc_fetch_revision $path]

    # Get status and log information

    vc_parse_cvs_status [set vc_file_props(status) [vc_fetch_status $path]]
    vc_parse_cvs_log    [set vc_file_props(log)    [vc_fetch_log $path]]
}


