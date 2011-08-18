# $Id: link-check.tcl,v 3.1 2000/02/29 04:39:18 jsc Exp $
# link-check.tcl 

# AOLserver link verifier
# this program crawls through all of your Web content and finds the dead links
# it should simply be placed in "link-check.tcl" somewhere accessible through an
# AOLserver 2.2 (2.1 might work also but no guarantees).  Request the URL and it 
# will grind through the Web content.

# Copyright Jin Choi (jsc@arsdigita.com) and Philip Greenspun (philg@mit.edu)
# distributed under the GNU General Public License

global webroot
global httproot
global debug_link_checker
global running_on_wimpy_machine

set debug_link_checker 0
# if you set this to 1 then the checker will sleep for 1 second periodically
# thus giving Web service a chance 
set running_on_wimpy_machine [ad_parameter WimpyMachineP machine 1]

# webroot, httproot

# webroot is the Unix fully qualified path
set webroot [ns_info pageroot]
set httproot [ns_conn location]

proc check_file {f} {
    ns_write "<li>$f\n<ul>\n"
    set stream [open $f]
    set content [read $stream]
    close $stream
    foreach url [ns_hrefs $content] {
	# we only want to check http: and relative refs
	if { [regexp -nocase "^mailto:" $url] || (![regexp -nocase "^http:" $url] && [regexp {^[^/]+:} $url]) || [regexp "^\\#" $url] } {
	    # it was a mailto or an ftp:// or something (but not http://)
	    # else that http_open won't like (or just plain #foobar)
	    # ns_write "<li>skipping $url because it doesn't look like HTTP:// or relative ref\n"
	    continue
	}
	
	# strip off any trailing #foo section directives to browsers
	regexp {^(.*/?[^/]+)\#[^/]+$} $url dummy url
	if [catch { set response [check_link $f $url] } errmsg ] {
	    # we got an error (probably a dead server)
	    set response "probably the foreign server isn't responding at all"
	}
	if {$response == 404 || $response == 405 || $response == 500 } {
	    # we should try again with a full GET 
	    # because a lot of program-backed servers return 404 for HEAD
	    # when a GET works fine
	    if [catch { set response [check_link $f $url 1] } errmsg] {
		set response "probably the foreign server isn't responding at all"
	    } 
	}
	if { $response != 200 && $response != 302 } {
	    ns_write "<li><a href=\"$url\">$url</a>: <font color=red>$response</font>\n"
	}
    }
    ns_write "</ul>\n"
}



proc walk_tree {dir procedure seen_already_cache {pattern {.*}}} {
    upvar $seen_already_cache seen
    global debug_link_checker
    global running_on_wimpy_machine

    # do this so that pwd works (so that we can avoid infinite loops)
    cd $dir

    set canonical_dirname [pwd]
    if [info exists seen($canonical_dirname)] {
	if { $debug_link_checker == 1 } {
	    ns_write "walk_tree: skipping directory $canonical_dirname (already seen)<br>"
	}
	return
    }

    set seen($canonical_dirname) 1
    
    if { $debug_link_checker == 1 } {
	ns_write "walk_tree: checking out directory $dir<br>\n"
    }
    foreach f [glob -nocomplain $dir/*] {
	if [file readable $f] {
	    if [file isdirectory $f] {
		if { $running_on_wimpy_machine == 1 } {
		    # we sleep for one second in order to not trash Web service
		    ns_sleep 1
		}
		walk_tree $f $procedure seen $pattern 
	    } else {
		if {[file isfile $f]} {
		    if {[ns_info winnt]} {
			set match [regexp -nocase $pattern $f]
		    } else {
			set match [regexp $pattern $f]
		    }
		    if $match {
			$procedure $f
		    }
		}
	    }
	}
    }
}


## Assumes url is a URL valid for use with ns_httpopen
proc get_http_status {url {use_get_p 0} {timeout 30}} { 
    if $use_get_p {
	set http [ns_httpopen GET $url "" $timeout] 
    } else {
	set http [ns_httpopen HEAD $url "" $timeout] 
    }
    # philg changed these to close BOTH rfd and wfd
    set rfd [lindex $http 0] 
    set wfd [lindex $http 1] 
    close $rfd
    close $wfd
    set headers [lindex $http 2] 
    set response [ns_set name $headers] 
    set status [lindex $response 1] 
    ns_set free $headers
    return $status
}

proc check_link  {base_file reference_inside_href {use_get_p 0}} {
    # base_file is the full file system path where the 
    # HTML was found; reference_inside_href is the string
    # that was inside the <a href=" tag
    global webroot
    global httproot
    if [regexp -nocase "^http://" $reference_inside_href] {
	# this is an external reference (or a ref to some alias
	# for this machine but let's ignore that)
	return [get_http_status $reference_inside_href $use_get_p]
    } else {
	# it is presumably a local reference, let's
	# convert it to a full Unix file system path
	# and [file exists ] for it
	if { [regexp "^/" $reference_inside_href] } {
	    # it is an absolute ref, e.g, "/photo"
	    # so we test for it from the server pageroot
	    set full_reference_file_name "$webroot$reference_inside_href"
	} else {
	    # it is a relative ref, e.g., "photo.html"
	    # so we test for it from wherever we were
	    set base_dirname [file dirname $base_file]
	    set full_reference_file_name [ns_normalizepath "${base_dirname}/$reference_inside_href"]
	}

	if [file exists $full_reference_file_name] {
	    return "200"
	} else {
	    return "file does not exist"
	}
    }
}


ReturnHeaders

ns_write "<html>
<head>
<title>Testing Links at $httproot</title>
</head>
<body bgcolor=white text=black>
<h2>Testing Links</h2>

at $httproot

<hr>

All HTML files:
<ul>
"

set seen_already_cache() 0
walk_tree $webroot check_file seen_already_cache {\.html$}


ns_write "</ul><hr>
<address><a href=\"mailto:jsc@arsdigita.com\">Jin S. Choi</a></address>
</body></html>"
