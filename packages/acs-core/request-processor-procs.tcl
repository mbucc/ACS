ad_library {

    The ACS Request Processor: the set of routines called upon every
    single HTTP request to an ACS server.

    @author Jon Salz (jsalz@arsdigita.com)
    @date 15 May 2000
    @cvs-id request-processor-procs.tcl,v 1.14.2.23 2001/01/15 22:32:43 kevin Exp
}

#####
#
#  PUBLIC API
#
#####

ad_proc ad_return { args } {

    Works like the "return" Tcl command, with one difference. Where "return" will 
    always return TCL_RETURN, regardless of the -code switch this way, by burying 
    it inside a proc, the proc will return the code you specify.

    <p>

    Why? Because "return" only sets the "returnCode" attribute of the
    interpreter object, which the function actually interpreting the procedure
    then reads and uses as the return code of the procedure.
    This proc adds just that level of processing to the statement.

    <p>

    When is that useful or necessary? Here:

<pre>
set errno [catch {
    return -code error "Boo!"
} error]
</pre>

    In this case, <code>errno</code> will always contain 2 (TCL_RETURN). 
    If you use ad_return instead, it'll contain what you wanted, 
    namely 1 (TCL_ERROR).
    

} {
    eval return $args
}


proc_doc rp_register_directory_map { url_section package { path_within_package "" } } {

Registers the directory packages/$package/$path_within_package
as the true location of a set of files under package management.
E.g., if the package "apm" is going to be served from "/apm" and
"/admin/apm" but the files are in /packages/acs-core/apm/www and
/packages/acs-core/apm/admin-www, call

<blockquote><pre>
rp_register_directory_map "apm" "acs-core" "apm"
</pre></blockquote>

} { 
    set directory $package
    if { ![empty_string_p $path_within_package] } {
	append directory "/$path_within_package"
    }

    ns_log "Notice" "Mapping URL stub /$url_section to directory /packages/$directory/www|admin-www"

    nsv_set rp_directory_map $url_section $directory
}

proc_doc rp_unregister_directory_map { url_section } {

Unregisters a directory mapping created by a call to rp_register_directory_map.

} {
    nsv_unset rp_directory_map $url_section
}

proc_doc rp_registered_proc_info_compare { info1 info2 } {

A comparison predicate for registered procedures, returning -1, 0, or 1
depending the relative sorted order of $info1 and $info2 in the procedure
list. Items with longer paths come first.

} {
    set info1_path [lindex $info1 1]
    set info2_path [lindex $info2 1]

    set info1_path_length [string length $info1_path]
    set info2_path_length [string length $info2_path]

    if { $info1_path_length < $info2_path_length } {
	return 1
    }
    if { $info1_path_length > $info2_path_length } {
	return -1
    }
    return 0
}

ad_proc ad_register_proc {
    {
	-debug f
	-noinherit f
	-description ""
    }
    method path proc args
} {

Registers a procedure (see ns_register_proc for syntax).
Use a method of "*" to register GET, POST, and HEAD filters.
If debug is set to "t", all invocations of the procedure will be ns_logged.
If proc is "rp_escape", the request processor will return "filter_ok" so that
any other registered filters or procs are invoked.

} {
    if { [string equal $method "*"] } {
	# Shortcut to allow registering filter for all methods. Just call ad_register_proc
	# again, with each of the three methods.
	foreach method { GET POST HEAD } {
	    eval ad_register_proc [list -debug $debug -noinherit $noinherit $method $path $proc] $args
	}
	return
    }

    if { [lsearch -exact { GET POST HEAD } $method] == -1 } {
	error "Method passed to ad_register_proc must be one of GET, POST, or HEAD"
    }

    # Obtain a lock on the list of registered procedures.
    set mutex [nsv_get rp_registered_procs mutex]
    ns_mutex lock $mutex

    set procs [nsv_get rp_registered_procs $method]
    set proc_info [list $method $path $proc $args $debug $noinherit $description [info script]]

    # Don't allow the same thing to be registered twice.
    if { [lsearch -exact $procs $proc_info] != -1 } {
	ns_log "Warning" "Procedure $proc already registered for $method $path"
	ns_mutex unlock $mutex
    }

    # Append and sort the list of procedures.
    lappend procs $proc_info
    set procs [lsort -command rp_registered_proc_info_compare $procs]

    ns_log "Notice" "Registering proc $proc for $method $path"

    # Reset the array entry, and free the lock.
    nsv_set rp_registered_procs $method $procs
    ns_mutex unlock $mutex
}

ad_proc ad_register_filter {
    {
	-debug f
        -priority 10000
	-critical f
	-description ""
    }
    kind method path proc args
} {

Registers a filter that gets called during page serving. The filter
should return one of 

<ul>
<li><code>filter_ok</code>, meaning the page serving
will continue; 
<li><code>filter_break</code> meaning the rest of the
filters of this type will not be called; 
<li><code>filter_return</code>
meaning the server will close the connection and end the request
processing.
</ul>

@param kind Specify preauth, postauth or trace.

@param method Use a method of "*"
to register GET, POST, and HEAD filters.

@param priority Priority is an
integer; lower numbers indicate higher priority.  

@param critical If a filter is not critical,
page viewing will not abort if a filter fails. 

@param debug If debug is set to "t",
all invocations of the filter will be ns_logged.



} {
    if { [string equal $method "*"] } {
	# Shortcut to allow registering filter for all methods.
	foreach method { GET POST HEAD } {
	    eval [concat [list ad_register_filter -debug $debug -priority $priority -critical $critical $kind $method $path $proc] $args]
	}
	return
    }

    if { [lsearch -exact { GET POST HEAD } $method] == -1 } {
	error "Method passed to ad_register_filter must be one of GET, POST, or HEAD"
    }

    # Obtain a lock on the list of filters.
    set mutex [nsv_get rp_filters mutex]
    ns_mutex lock $mutex

    # Append the filter to our list.
    set filters [nsv_get rp_filters "$method,$kind"]
    set filter_info [list $priority $kind $method $path $proc $args $debug $critical $description [info script]]

    # Refuse to register the same thing twice.
    if { [lsearch -exact $filters $filter_info] != -1 } {
	ns_log "Warning" "$kind filter $proc already registered for $method $path"
	ns_mutex unlock $mutex
	return
    }

    # Append the filter and sort based on priority. The -index flag to lsort
    # sorts based on the nth item of each sublist; priority is the 0'th item.
    lappend filters $filter_info
    set filters [lsort -integer -index 0 $filters]

    # Set the array entry and release the lock.
    ns_log "Notice" "Registering $kind filter $proc for $method $path with priority $priority"
    nsv_set rp_filters "$method,$kind" $filters

    ns_mutex unlock $mutex
}

proc_doc rp_html_directory_listing { dir } {

Generates an HTML-formatted listing of a directory. This is mostly
stolen from _ns_dirlist in an AOLserver module (fastpath.tcl).

} {
    # Create the table header.
    set list "
<table>
<tr align=left><th>File</th><th>Size</th><th>Date</th></tr>
<tr align=left><td colspan=3><a href=../>..</a></td></tr>
"

    # Loop through the files, adding a row to the table for each.
    foreach file [glob -nocomplain $dir/*] {
	set tail [file tail $file]
	set link "<a href=$tail>$tail</a>"

	# Build the stat array containing information about the file.
	file stat $file stat
	set size [expr $stat(size) / 1000 + 1]K
	set mtime $stat(mtime)
	set time [clock format $mtime -format "%d-%h-%Y %H:%M"]

	# Write out the row.
	append list "<tr align=left><td>$link</td><td>$size</td><td>$time</td></tr>\n"
    }
    append list "</table>"
    return $list
}

#####
#
#  PRIVATE API
#
#####

#####
#
# NSV arrays used by the request processor:
#
#   - rp_filters(mutex)
#         A mutex guarding the rp_filters NSV.
#
#   - rp_filters($method,$kind), where $method in (GET, POST, HEAD)
#       and kind in (preauth, postauth, trace)
#         A list of $kind filters to be considered for HTTP requests with method
#         $method. The value is of the form
#
#             [list $priority $kind $method $path $proc $args $debug $critical\
#                 $description $script]
#
#   - rp_registered_procs(mutex)
#         A mutex guarding the rp_registered_procs NSV.
#
#   - rp_registered_procs($method), where $method in (GET, POST, HEAD)
#         A list of registered procs to be considered for HTTP requests with
#         method $method. The value is of the form
#
#             [list $method $path $proc $args $debug $noinherit $description $script]
#
#   - rp_system_url_sections($url_section)
#         Indicates that $url_section is a system directory (like SYSTEM) which is
#         exempt from Host header checks and session/security handling.
#
# ad_register_filter and ad_register_procs are used to add elements to these NSVs.
# They need to be protected by mutexes because we need to support inserting an item
# as an atomic opertaion (to keep them in sorted order).
#
# We use lists rather than arrays for these data structures since "array get" and
# "array set" are rather expensive and we want to keep lookups fast.
#
#####
#
# FUTURE ENHANCEMENTS (jsalz@mit.edu)
#
# - Our idea of preauth/postauth makes no sense ("auth" in preauth/postauth
#   refers to HTTP basic authentication, not the actual ACS-user-session
#   authentication). We should really figure out what to do about this!
#
# - The abstract URL system should be subsumed into this file.
#
# - Developer support in filters/registered procedures.
#
# OPTIMIZATIONS (jsalz@mit.edu)
#
# It would be most excellent to optimize this all soon.
#
# A good way to do this is based on the first path element: we could have
# an NSV containing a mapping from the first path element to a list of
# proc_infos with that element. E.g., when I register GET /wp/attach, the
# information goes in the rp_registered_procs(GET,wp) NSV. Then to see if
# a URL matches, I merely need to look through the list of matching
# elements, rather than every single procedure ever registered.
#
# Registered procs with wildcards in the first path element (of which there
# are few) would need to be cached in every single one of these arrays.
#
#####

proc_doc rp_url_component_list { url } {

Returns a list of components in $url, with a trailing empty element
(representing the magic "index file") if the component has a trailing slash.
For example:

<ul>
<li><tt>rp_url_component_list "/"</tt> yields <tt>[list ""]</tt>
<li><tt>rp_url_component_list "/foo/bar"</tt> yields <tt>[list "foo" "bar"]</tt>
<li><tt>rp_url_component_list "/foo/bar/"</tt> yields <tt>[list "foo" "bar" ""]</tt>
</ul>

} {
    return [lrange [split $url "/"] 1 end]
}

proc_doc rp_url2file { urlv } {

Returns the file corresponding to a particular URL (taking mappings made with
<tt>rp_register_directory_map</tt> into account).

} {
    if { [llength $urlv] < 1 } {
	error "Input list to rp_url2file must contain at least one component"
    }

    set url_0 [lindex $urlv 0]
    set url_1 [lindex $urlv 1]

    # Check to see if a mapping in rp_register_directory_map applies to this
    # URL. If someone registered "/foo" and this URL is "/foo/bar", replace
    # the first component with the mapping.
    if { [nsv_exists rp_directory_map $url_0] } {
	set fs_directory [nsv_get rp_directory_map $url_0]
	return "[acs_root_dir]/packages/[join [lreplace $urlv 0 0 "$fs_directory/www"] "/"]"
    }

    # If someone registered "/foo" and this URL is "/admin/foo/bar", replace
    # the first two components with the mapping.
    if { [string equal $url_0 "admin"] && \
	    [nsv_exists rp_directory_map $url_1] } {
	set fs_directory [nsv_get rp_directory_map $url_1]
	return "[acs_root_dir]/packages/[join [lreplace $urlv 0 1 "$fs_directory/admin-www"] "/"]"
    }

    # If someone registered "/foo" and this URL is "/doc/foo/bar", replace
    # the first two components with the mapping
    if { [string equal $url_0 "doc"] && \
	    [nsv_exists rp_directory_map $url_1] } {
	set fs_directory [nsv_get rp_directory_map $url_1]
	return "[acs_root_dir]/packages/[join [lreplace $urlv 0 1 "$fs_directory/doc"] "/"]"
    }

    # No mappings - just use [ns_info pageroot].
    return "[ns_info pageroot]/[join $urlv "/"]"
}

proc_doc rp_call_filters { conn kind } {

Invokes filters in the rp_filters arrays.
$kind must be one of preauth, postauth, and trace.

} {
    rp_debug "Calling $kind filters"

    # Loop through all filters in order of priority (they're stored in sorted order
    # in the NSV).
    foreach filter_info [nsv_get rp_filters "[ns_conn method],$kind" ] {
	set path [lindex $filter_info 3]
	if { [string match $path [ad_conn url]] } {
	    # We found a match with the path - apply the filter, catching any
	    # errors that might occur.

	    set startclicks [clock clicks]

	    set errno [catch {
		set proc [lindex $filter_info 4]
		set args [lindex $filter_info 5]
		set debug [lindex $filter_info 6]
		set critical [lindex $filter_info 7]

		# Use [info args $proc] to obtain a list of the names of all
		# arguments to the procedure $proc. Place the number of arguments
		# into $proc_argcount.
		set proc_args [info args $proc]
		set proc_argcount [llength $proc_args]

		# Perform some magic to figure out how to invoke the procedure
		# (differs based on the number of elements).
		if { [string equal [lindex $proc_args [expr { [llength $proc_args] - 2 }]] "args"] } {
		    # The second-to-last argument name can be "args", in which case
		    # all the arguments are supposed to be wrapped in a list and placed
		    # there. So wrap the arguments in a list.
		    set args [list $args]
		}
		set actual_argcount [llength $args]

		if { [string equal $debug "t"] } {
		    ns_log "Notice" "Executing filter $proc for [ns_conn method] [ad_conn url]..."
		}

		if { $actual_argcount >= 3 || $proc_argcount - $actual_argcount == 2 } {
		    # Procedure has conn and kind.
		    set result [eval $proc [concat [list $conn] $args [list $kind]]]
		} elseif { $proc_argcount - $actual_argcount == 1 } {
		    # Procedure has kind.
		    set result [eval $proc [concat $args [list $kind]]]
		} else {
		    # Procedure has neither conn nor kind.
		    set result [eval $proc $args]
		}
		
		if { [string equal $debug "t"] } {
		    ns_log "Notice" "Done executing filter $proc."
		}

		if { [string equal $result "filter_break"] } {
		    # Halt invocations of filters.
		    set return "filter_break"
		} elseif { [string equal $result "filter_return"] } {
		    # We're outta here!
		    set return "filter_return"
		} elseif { ![string equal $result "filter_ok"] } {
		    ns_log "Error" "Invalid result \"$result\" from filter $proc: should be filter_ok, filter_break, or filter_return"
		    if { [string equal $critical "t"] } {
			return -code error "Critical filter $proc failed."
		    }
		}
	    } errmsg]

            if { $errno } {
		# Uh-oh - an error occurred. Dump a stack trace to the log.
		# Eventually we'll be really nice and write a server error
		# message containing the stack trace (a la ClientDebug) if
		# the user is an administrator.

		global errorInfo
		ad_call_proc_if_exists ds_add rp [list filter $filter_info $startclicks [clock clicks] "error" $errorInfo]
		ns_log "Error" "Filter $proc returned error: $errorInfo"
		if { $critical == "t" } {
		    return -code error "Critical filter $proc failed."
		}
	    }

	    if { [info exists return] } {
		ad_call_proc_if_exists ds_add rp [list filter $filter_info $startclicks [clock clicks] $return]
		
		# If the return variable was set, we want to return that value
		# (e.g., filter_break or filter_return).


		return $return
	    }
	    ad_call_proc_if_exists ds_add rp [list filter $filter_info $startclicks [clock clicks]]
	}
    }

    # No problems!
    return "filter_ok"
}

ad_proc rp_eval { kind info argv } {
    set startclicks [clock clicks]
    set errno [catch { uplevel $argv } error]
    global errorCode
    global errorInfo
    if { $errno == 0 || $errno == 2 } {
	ad_call_proc_if_exists ds_add rp [list $kind $info $startclicks [clock clicks] $error]
    } else {
	ad_call_proc_if_exists ds_add rp [list $kind $info $startclicks [clock clicks] "error" $errorInfo]
    }
    return -code $errno -errorcode $errorCode -errorinfo $errorInfo $error
}

proc_doc rp_debug { string } {

    Logs a debugging message, including a high-resolution (millisecond) timestamp.

} {
    if { [ad_parameter DebugP request-processor 0] } {
	global ad_conn
	set clicks [clock clicks]
        ad_call_proc_if_exists ds_add rp [list debug $string $clicks $clicks]
    }
    if { [ad_parameter LogDebugP request-processor 0] } {
	global ad_conn
	if { [info exists ad_conn(start_clicks)] } {
	    set timing [expr { ([clock clicks] - $ad_conn(start_clicks)) / 1000 }]
	} else {
	    set timing "?"
	}
	ns_log "Notice" "RP ($timing ms): $string"
    }
}


proc_doc rp_handler_preauth { conn ignore } {

The request handler, which responds to absolutely every HTTP request made to
the server.

} {
    set errno [catch {
	#####
	#
	# Initialize the environment: unset the ad_conn array, and populate it with
	# a few things.
	#
	#####

	global ad_conn
	if { [info exists ad_conn] } {
	    unset ad_conn
	}
	set ad_conn(request) [nsv_incr ad_security request]
	set ad_conn(sec_validated) ""
	set ad_conn(browser_id) ""
	set ad_conn(session_id) ""
	set ad_conn(user_id) 0
	set ad_conn(token) ""
	set ad_conn(last_issue) ""
	set ad_conn(deferred_dml) ""
	set ad_conn(start_clicks) [clock clicks]

	rp_debug "Serving request: [ns_conn url]"

	set url [ns_urldecode [ns_conn url]]
	if { [ns_queryexists acs-type] } {
	    set ad_conn(requested_type) [ns_queryget acs-type]
	    ns_set delkey [ns_getform] acs-type
	}

	set urlv [rp_url_component_list $url]

	# Here we'd play with $urlv, stripping any scoping/subcommunity information
	# from the beginning of the URL and setting the appropriate ad_conn fields.
	# For now, since we don't support scoping here, we don't do anything to
	# $urlv.

	# The URL, sans scoping information, goes in ad_conn(url).
	set ad_conn(url) "/[join $urlv "/"]"
	set ad_conn(urlv) $urlv

	#####
	#
	# See if any libraries have changed. This may look expensive, but all it
	# does is check an NSV.
	#
	#####

	rp_debug "Checking for changed libraries"

	# We wrap this in a catch, because we don't want an error here to 
	# cause the request to fail.

	if { [catch { apm_load_any_changed_libraries } error] } {
	    global errorInfo
	    ns_log "Error" $errorInfo
	}

	#####
	#
	# Log stuff for developer support.
	#
	#####

	rp_debug "Performing developer support logging"
	ad_call_proc_if_exists ds_collect_connection_info

	# Skip a few steps for requests to system directories (like SYSTEM) - don't
	# check the Host header, and don't check any cookies.

	if { ![nsv_exists rp_system_url_sections [lindex $urlv 0]] } {
	    #####
	    #
	    # Check the Host header (if provided). If it doesn't look like [ns_conn location]
	    # (a combination of the Hostname and Port specified under the nssock module in
	    # the server.ini file), issue a redirect.
	    #
	    #####

	    if { [ad_parameter ForceHostP "" 1] } {
		rp_debug "Checking the host header"

		set host_header [ns_set iget [ns_conn headers] "Host"]
		regexp {^([^:]*)} $host_header "" host_without_port
		regexp {^https?://([^:]+)} [ns_conn location] "" desired_host_without_port
		if { ![empty_string_p $host_header] && \
			![string equal $host_without_port $desired_host_without_port] } {
		    rp_debug "Host header is set to \"$host_header\"; forcing to \"[ns_conn location]\""
		    if { [ns_getform] != "" } { 
			set query "?[export_entire_form_as_url_vars]"
		    }
		    ad_returnredirect "[ns_conn location][ns_conn url]$query"
		    return "filter_return"
		}
	    }

	    #####
	    #
	    # Read in and/or generate security cookies.
	    #
	    #####

	    rp_debug "Handling security"

	    # Read in the security cookies.
	    sec_read_security_info

	    # Use sec_log to log the cookies (for debugging's sake).
	    sec_log "ad_browser_id=<<[ad_get_cookie "ad_browser_id"]>>; ad_session_id=<<[ad_get_cookie "ad_session_id"]>>"

	    if { [empty_string_p $ad_conn(browser_id)] } {
		# Assign a browser_id
		set ad_conn(browser_id) [db_nextval sec_id_seq]
		sec_log "Assigned browser ID $ad_conn(browser_id)"
		ad_set_cookie -expires never "ad_browser_id" $ad_conn(browser_id)
	    }

	    if { [empty_string_p $ad_conn(session_id)] || \
		    $ad_conn(last_issue) > [ns_time] + [sec_session_timeout] || \
		    $ad_conn(last_issue) + [sec_session_timeout] < [ns_time] } {
		# No session or user ID yet (or last_issue is way in the future, or session is
		# expired).

		if { [empty_string_p $ad_conn(last_issue)] } {
		    set ad_conn(last_issue) ""
		}
		sec_log "Bad session: session ID was \"$ad_conn(session_id)\"; last_issue was \"$ad_conn(last_issue)\"; ns_time is [ns_time]; timeout is [sec_session_timeout]"
		
		ad_assign_session_id
	    } else {
		# The session already exists and is valid.

		set last_hit [ns_time]
		set session_id $ad_conn(session_id)
		# Can't use bind variables here because ad_defer_dml can't find the values.
		if { $ad_conn(last_issue) + [sec_session_cookie_reissue] < [ns_time] } {
		    ad_defer_dml db_dml update_last_hit "
			update sec_sessions
			set last_hit = $last_hit
			where session_id = $session_id"

		    # This should probably be changed to util_memoize_seed.
		    util_memoize_flush "sec_get_session_info $ad_conn(session_id)"
		    sec_generate_session_id_cookie
		}
	    }
	}

	#####
	#
	# Initialize the document processor, in case something decides to return
	# a document.
	#
	#####

	doc_init
	
	#####
	#
	# Invoke applicable preauth filters.
	#   
	#####

	# filters based on ad_conn(url)
	if { [rp_call_filters $conn preauth] == "filter_return" } {
	    return "filter_return"
	}
	
	return filter_ok
    } error]

    db_release_unused_handles

    global errorInfo
	
    # If no error occurred, we expect a "return" exception. When this is the case,
    # serve the document in the environment (if any) and return.
    if { $errno == 2 } {
	return $error
    } 
    rp_write_error
    return "filter_return"
}



proc_doc rp_handler_postauth { conn ignore } {

The request handler, which responds to absolutely every HTTP request made to
the server.

} {
    set errno [catch {

	global ad_conn
	
	#####
	#
	# Invoke applicable postauth filters.
	#
	#####

	if { [rp_call_filters $conn postauth] == "filter_return" } {
	    return "filter_return"
	}


	#####
	#
	# Invoke a registered procedure, if we find one.
	#
	#####

	rp_debug "Looping through registered procedures"

	# Loop through the array of registered procs, dispatching if we find a match.
	foreach proc_info [nsv_get rp_registered_procs [ns_conn method]] {
	    set proc_path [lindex $proc_info 1]
	    set proc_noinherit [lindex $proc_info 5]
	    if { [string match $proc_path $ad_conn(url)] || \
		  $proc_noinherit == "f" && [string match "$proc_path/*" $ad_conn(url)] } {
		# Found a match. Execute the handler procedure.

		set proc [lindex $proc_info 2]
		set args [lindex $proc_info 3]

		if { [string equal $proc "rp_escape"] } {
		    return "filter_ok"
		}

		if { [set errno [catch {
		    set startclicks [clock clicks]

		    if { [llength [info procs $proc]] == 0 } {
			# [info procs $proc] returns nothing when the procedure has been
			# registered by C code (e.g., ns_returnredirect). Assume that neither
			# "conn" nor "why" is present in this case.
			eval $proc $args
		    } else {
			# Need to eval different things depending on whether the proc
			# has the $conn element.
			if { [llength [info args $proc]] - [llength $args] == 2 } {
			    # Procedure has conn argument.
			    eval $proc [list $conn] "dontuseme"
			} elseif { [llength [info args $proc]] - [llength $args] == 1 } {
			    # Procedure has conn argument.
			    eval $proc [list $conn] $args
			} else {
			    eval $proc $args
			}
		    }
		} error]] } {
		    global errorCode
		    global errorInfo
		    ad_call_proc_if_exists ds_add rp [list registered_proc $proc_info $startclicks [clock clicks] "error" $errorInfo]
		    if { $errno == 1 && [string compare $error "<<AD_SCRIPT_ABORT>>"] } {
			ad_return -code error -errorcode $errorCode -errorinfo $errorInfo $error
		    }
		} else {
		    ad_call_proc_if_exists ds_add rp [list registered_proc $proc_info $startclicks [clock clicks]]
		}

		return "filter_return"
	    }
	}


	#####
	#
	# Certain URLs should be left to AOLserver to handle, e.g. nscgi.so, nsphp.so, etc.
	#
	#####

	foreach path [ad_parameter_all_values_as_list LeaveAloneUrl request-processor] {
	    if { [string match $path $ad_conn(url)] } {
		return "filter_ok"
	    }
	}

	#####
	#
	# Invoke the abstract URL system.
	#
	#####

	rp_debug "Calling rp_abstract_url_server"

	rp_abstract_url_server

	return "filter_return"
    } return]

    global errorInfo
	
    # If no error occurred, we expect a "return" exception. When this is the case,
    # serve the document in the environment (if any) and return.
    if { $errno == 2 } {

	if { [doc_exists_p] } {
	    rp_debug "Invoking document processor"

	    set errno [catch doc_serve_document error]
	    if { $errno == 0 } {
		rp_debug "Exiting request processor after serving document"
		return $return
	    }
	} else {
	    rp_debug "Exiting request processor after resource has been ns_written"
	    return $return
	}
    }
    rp_write_error
    
    return "filter_return"
}

proc_doc rp_write_error {} {
    Writes an error to the connection.
} {
    rp_debug "Writing error"

    # Boo! That'll be 500.
    global errorInfo
    if { [llength [info procs ds_collection_enabled_p]] == 1 && [ds_collection_enabled_p] } {
	ds_add conn error $errorInfo
    }

    if { ![ad_parameter "RestrictErrorsToAdminsP" "" 0] || \
	     [util_memoize [list rp_lookup_administrator_p [ad_get_user_id]]] } {
	if { [ad_parameter "AutomaticErrorReportingP" "rp" 0] } { 
	    set error_url [ns_conn url]
	    set error_info $errorInfo
	    set report_url [ad_parameter "ErrorReportURL" "rp" ""]
	    if { [empty_string_p $report_url] } {
		ns_log Error "Automatic Error Reporting Misconfigured.  Please add a field in the acs/rp section of form ErrorReportURL=http://your.errors/here."
	    } else {
		set auto_report 1
		ns_returnerror 200 "</table></table></table></h1></b></i>
		<form method=POST action=\"$report_url\">
[export_form_vars error_url error_info]
This file has generated an error.  
<input type=submit value=\"Report this error\">
</form><hr>
	<blockquote><pre>[ns_quotehtml $error_info]</pre></blockquote>[ad_footer]"
	    }
	} else {
	    # No automatic report.
	    ns_returnerror 200 "</table></table></table></h1></b></i>
	<blockquote><pre>[ns_quotehtml $errorInfo]</pre></blockquote>[ad_footer]"
	}
    }  else {
	ns_returnerror 200 ""
    }
    ns_log "Error" $errorInfo
}

proc_doc ad_script_abort {} {

    Aborts the current running Tcl script, returning to the request processor.

} {
    error "<<AD_SCRIPT_ABORT>>"
}

proc_doc ad_conn { which } {

    Returns a property about the connection.
    See the <a href="/doc/core-arch-guide/request-processor#ad_conn">request processor documentation</a>
    for a list of allowable values.

} {
    global ad_conn
    switch $which {
	url -
	file -
	full_url -
	canonical_url -
	browser_id -
	session_id -
	user_id -
	token -
	requested_type -
	request -
	start_clicks -
	deferred_dml {
	    if { [info exists ad_conn($which)] } {
		return $ad_conn($which)
	    } else {
		return ""
	    }
	}
	extension {
	    if { [info exists ad_conn(file)] } {
		return [file extension $ad_conn(file)]
	    } else {
		return ""
	    }
	}
    }

    error "ad_conn $which is invalid: argument must be one of url, file, canonical_url, browser_id, session_id, last_visit, user_id, token, deferred_dml, or extension"
}

if { [apm_first_time_loading_p] } {
    # Initialize nsv_sets

    nsv_set rp_filters mutex [ns_mutex create]
    nsv_set rp_registered_procs mutex [ns_mutex create]

    nsv_array set rp_filters [list]
    nsv_array set rp_registered_procs [list]

    # The following stuff is in a -procs.tcl file rather than a -init.tcl file
    # since we want it done really really early in the startup process. Don't
    # try this at home!

    foreach method { GET POST HEAD } {
	nsv_set rp_registered_procs $method [list]
	foreach kind { preauth postauth trace } {
	    nsv_set rp_filters "$method,$kind" [list]
	}

	ns_log "Notice" "Registering $method / for pipeline processing"
	ns_register_filter preauth $method /* rp_handler_preauth

	ns_log "Notice" "Registering $method / for pipeline processing"
	ns_register_filter preauth $method /* rp_handler_postauth

	ns_log "Notice" "Setting up trace filter for \"$method\" method"
	ns_register_filter trace $method /* rp_call_filters
    }

    if { [llength [info procs _ad_ns_register_filter]] == 0 && \
	    [ad_parameter DisableNSRegisterCallsP "" 1] } {
	# Draconian: Disable ns_register_filter and ns_register_proc.
	rename ns_register_filter _ad_ns_register_filter
	rename ns_register_proc _ad_ns_register_proc

	proc ns_register_filter args {
	    error "ns_register_filter is now disabled. Please use ad_register_filter instead."
	}
	proc ns_register_proc args {
	    error "ns_register_proc is now disabled. Please use ad_register_proc instead."
	}
    }
}


