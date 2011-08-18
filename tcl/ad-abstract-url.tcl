# /tcl/ad-abstract-url.tcl
#
# Provides support for abstract URL processing (see doc/abstract-url.html).
#
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        27 Feb 2000
#
# $Id: ad-abstract-url.tcl,v 3.3.2.4 2000/04/28 15:08:07 carsten Exp $

util_report_library_entry

# we must take conn as an argument so that it is defined if we source 
# a legacy .tcl script using $conn ; we also need the ignore arg
# so that AOLserver knows to put a valid conn ID into the var
proc_doc ad_handle_abstract_url {conn ignore} {
A registered procedure which searches through the file system for an appropriate
file to serve. The algorithm is as follows:

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

} {
    global ad_conn

    # The URL, minus the scoping components. Right now this is the whole URL (since we
    # don't handle scoping here).
    set ad_conn(url) [ns_urldecode [ns_conn url]]

    set ad_conn(canonicalurl) $ad_conn(url)
    set ad_conn(file) ""

    if { [lsearch -regexp [ns_conn urlv] {^\.\.+$}] != -1 } {
	# Don't serve anything containing two or more periods as a path element
	ns_returnforbidden
	return
    }

    # Determine the path corresponding to the user's request (i.e., prepend the document root)
    set path [ns_url2file $ad_conn(url)]

    if { [file isdirectory $path] } {
	if { ![regexp {/$} $ad_conn(url)] } {
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
	    set dir_index 1
	    set path "[string trimright $path /]/index"
	    set ad_conn(canonicalurl) "[string trimright $ad_conn(canonicalurl)]/index"
	}
    }

    if { ![file isfile $path] } {
	# It doesn't exist - glob for the right file.
	if { ![file isdirectory [file dirname $path]] } {
	    ns_returnnotfound
	    return
	}

	set ad_conn(file) [ad_get_true_file_path $path]

	# Nothing at all found! 404 time.
	if { ![string compare $ad_conn(file) ""] } {
	    if { [info exists dir_index] && [nsv_get ad_abstract_url directory_listing_p] } {
		_ns_dirlist
		return
	    } else {
		ns_returnnotfound
		return
	    }
	}

	set ad_conn(canonicalurl) "[string trimright [file dirname $ad_conn(canonicalurl)] /]/[file tail $ad_conn(file)]"
    } else {
	set ad_conn(file) $path
    }

    set extension [file extension $ad_conn(file)]
    if { $extension == ".tcl" } {
	# Tcl file - use source.
	source $ad_conn(file)
    } elseif { $extension == ".adp" } {
	# ADP file - parse and return the ADP.
	set adp [ns_adp_parse -file $ad_conn(file)]
	set content_type [ns_set iget [ns_conn outputheaders] "content-type"]
	if { $content_type == "" } {
	    set content_type "text/html"
	}
	ns_return 200 $content_type $adp
    } elseif { $extension == ".html" || $extension == ".htm" } {
	ad_serve_html_page $conn
    } else {
	# Some other random kind of find - return it.
	ns_returnfile 200 [ns_guesstype $ad_conn(file)] $ad_conn(file)
    }
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

# Make sure ad_abstract_url array exists
nsv_set ad_abstract_url . ""

if { ![nsv_exists ad_abstract_url registered] && \
	[ad_parameter "EnableAbstractURLsP" "abstract-url" 0] } {
    nsv_set ad_abstract_url registered "t"

    set listings [ns_config "ns/server/[ns_info server]" "directorylisting" "none"]
    if { [string compare $listings "fancy"] || [string compare $listings "simple"] } {
	nsv_set ad_abstract_url directory_listing_p 1
    } else {
	nsv_set ad_abstract_url directory_listing_p 0
    }

    foreach method { GET POST HEAD } {
	ns_log "Notice" "Registering $method / for abstract URL processing"
	ns_register_proc $method / ad_handle_abstract_url
    }
}

util_report_successful_library_load

