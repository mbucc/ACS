ad_library {

    Provides support for abstract URL processing (see doc/abstract-url.html).

    @creation-date 27 Feb 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id abstract-url-procs.tcl,v 1.7.2.5 2000/09/22 01:33:48 kevin Exp

}

proc_doc rp_abstract_url_server {} {

Searches through the file system for an appropriate
file to serve, based on $ad_conn(urlv). The algorithm is as follows:

<ol>

<li>If the URL specifies a directory but doesn't have a trailing slash,
append a slash to the URL and redirect (just like AOLserver would).

<li>If the URL specifies a directory and does have a trailing slash,
append "index" to the URL (so we'll search for an <tt>index.*</tt> file
in the filesystem).

<li>If the file corresponding to the requested URL exists (probably because the
user provided the extension), just deliver the file.

<li>Find a file in the file system with the provided URL as the root (i.e.,
some file exists which is the URL plus some extension). Give precedence to
extensions specified in the <tt>ExtensionPrecedence</tt> parameter in the
<tt>abstract-url</tt> configuration section (in the order provided).
If such a file exists, deliver it.

<li>The requested resource doesn't exist - return a 404 Not Found.

</ol>

This routine should really be part of the request processor.

} {
    global ad_conn

    set ad_conn(canonical_url) $ad_conn(url)
    set ad_conn(full_url) $ad_conn(url)

    # Determine the path corresponding to the user's request (i.e., prepend the document root)
    set path [rp_url2file $ad_conn(urlv)]

    if { [file isdirectory $path] } {
	# The path specified was a directory; return its index file.

	rp_debug "Looking for index in directory $path"

	if { [string index $ad_conn(url) end] != "/" } {
	    # Directory name with no trailing slash. Redirect to the same URL but with
	    # a trailing slash.

	    set url "[ns_conn url]/"
	    if { [ns_conn query] != "" } {
		append url "?[ns_conn query]"
	    }
	    
	    ad_returnredirect $url
	    return
	} else {
	    # Directory name with trailing slash. Search for an index.* file.
	    # Remember the name of the directory in $dir_index, so we can later
	    # generate a directory listing if necessary.
	    set dir_index $path
	    set path "[string trimright $path /]/index"
	    append ad_conn(canonical_url) "index"
	}
    } else {
	# If there's a trailing slash on the path, the URL must refer to a directory
	# (which we know doesn't exist, since [file isdirectory $path] returned 0).
	if { [string equal [string index $path end] "/"] } {
	    ns_returnnotfound
	    return
	}
    }

    if { ![file isfile $path] } {
	# The path provided doesn't correspond directly to a file - we need to glob.

	if { ![file isdirectory [file dirname $path]] } {
	    ns_returnnotfound
	    return
	}

	rp_debug "Searching for $path.*"

	set ad_conn(file) [ad_get_true_file_path $path]

	# Nothing at all found! 404 time.
	if { ![string compare $ad_conn(file) ""] } {
	    if { [info exists dir_index] } {
		set listings [ns_config "ns/server/[ns_info server]" "directorylisting" "none"]
		if { [lsearch -exact { fancy simple } $listings] != -1 } {
		    # Oh, wait: actually we were looking for a nonexistent index file, and
		    # directory indexing is enabled. Create a directory listing.
		    ns_returnnotice 200 "Directory listing of $dir_index" [rp_html_directory_listing $dir_index]
		    return
		}
	    } else {
		ns_returnnotfound
		return
	    }
	}

	# Replace the last element of the full URL with the actual file name.
	if {[regexp {(.+)/$} $ad_conn(full_url) match dirname]} {
	    set ad_conn(full_url) "[file join $dirname [file tail $ad_conn(file)]]"
	} else {
	    set ad_conn(full_url) "[string trimright [file dirname $ad_conn(full_url)] /]/[file tail $ad_conn(file)]"
	}


    } else {
	# It's actually a file. Ensure that there are no trailing slashes (which
	# might cause handlers to be subverted) and deliver it directly.
	set ad_conn(file) $path
    }

    set ad_conn(canonical_url) [file rootname $ad_conn(full_url)]
    set extension [file extension $ad_conn(file)]

    if { [nsv_exists rp_extension_handlers $extension] } {
	set handler [nsv_get rp_extension_handlers $extension]
	rp_debug "Serving $ad_conn(file) with $handler"
	set startclicks [clock clicks]
	if { [set errno [catch $handler error]] } {

	    # If the error is "<<AD_SCRIPT_ABORT>>", it's not really
	    # an error; it's an instruction to stop further
	    # processing.
	    #
	    if { $errno == 1 && [string equal $error "<<AD_SCRIPT_ABORT>>"] } {
		return
	    }

	    global errorCode
	    global errorInfo
	    ad_call_proc_if_exists ds_add rp [list serve_file [list $ad_conn(file) $handler] $startclicks [clock clicks] error $errorInfo]
	    return -code $errno -errorcode $errorCode -errorinfo $errorInfo $error
	}
	ad_call_proc_if_exists ds_add rp [list serve_file [list $ad_conn(file) $handler] $startclicks [clock clicks]]
    } else {
	# Some other random kind of find - guess the type and return it.
	set type [ns_guesstype $ad_conn(file)]
	rp_debug "Serving $ad_conn(file) as $type"
	set startclicks [clock clicks]
	ad_returnfile 200 $type $ad_conn(file)
	ad_call_proc_if_exists ds_add rp [list serve_file [list $ad_conn(file) ad_returnfile] $startclicks [clock clicks]]
    }
}

proc_doc rp_lookup_administrator_p { user_id } { Used with util_memoize to cache the results of ad_administrator_p. } {
    set value [ad_administrator_p $user_id]
    return $value
}

proc_doc ad_get_true_file_path { path } { Given a path in the filesystem, returns the file that would be served, trying all possible extensions. Returns an empty string if there's no file "$path.*" in the filesystem (even if the file $path itself does exist). } {
    # Sub out funky characters in the pathname, so the user can't request
    # http://www.arsdigita.com/*/index (causing a potentially expensive glob
    # and bypassing registered procedures)!
    regsub -all {[^0-9a-zA-Z_/.]} $path {\\&} path_glob

    # Grab a list of all available files with extensions.
    set files [glob -nocomplain "$path_glob.*"]
    
    # Search for files in the order specified in ExtensionPrecedence.
    set precedence [ad_parameter "ExtensionPrecedence" "abstract-url" "tcl"]
    foreach extension [split [string trim $precedence] ","] {
	if { [lsearch $files "$path.$extension"] != -1 } {
	    return "$path.$extension"
	}
    }

    # None of the extensions from ExtensionPrecedence were found - just pick
    # the first in alphabetical order.
    if { [llength $files] > 0 } {
	set files [lsort $files]
	return [lindex $files 0]
    }

    # Nada!
    return ""
}

nsv_array set rp_extension_handlers [list]

proc_doc rp_register_extension_handler { extension args } { Registers a proc used to handle requests for files with a particular extension. } {
    if { [llength $args] == 0 } {
	error "Must specify a procedure name"
    }
    ns_log "Notice" "Registering [join $args " "] to handle files with extension $extension"
    nsv_set rp_extension_handlers ".$extension" $args
}

proc_doc rp_handle_tcl_request {} { Handles a request for a .tcl file. } {
    source [ad_conn file]
}

proc_doc rp_handle_adp_request {} { Handles a request for an .adp file. } {
    doc_init
    set adp [ns_adp_parse -file [ad_conn file]]

    if { [doc_exists_p] } {
	doc_set_property body $adp
	doc_serve_document
    } else {
	set content_type [ns_set iget [ns_conn outputheaders] "content-type"]
	if { $content_type == "" } {
	    set content_type "text/html"
	}
	doc_return  200 $content_type $adp
    }
}

proc_doc rp_handle_html_request {} { Handles a request for an HTML file. } {
    ad_serve_html_page [ad_conn file]
}
