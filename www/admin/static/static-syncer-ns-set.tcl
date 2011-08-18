# $Id: static-syncer-ns-set.tcl,v 3.0 2000/02/06 03:30:30 ron Exp $
# static-pages-syncer.tcl 

# this program crawls through all of your Web content and finds pages to 
# stuff into the static_pages table

# Copyright Jin Choi (jsc@arsdigita.com) and Philip Greenspun (philg@mit.edu)
# distributed under the GNU Public License

# modified to use ns_set instead of Tcl globals

# modified November 6, 1999 to check the ad.ini file 
# for exclusion patterns 
# modified December 27, 1999 by philg to check the ad.ini
# file for IncludeRegexp (part of a grand scheme to make 
# .adp files take advantage of comments and links)

proc ad_running_on_wimpy_machine_p {} {
    return 0
}

proc ad_debug_static_page_syncer_p {} {
    return 0
}

proc ad_check_file_for_sync {f db} {
    ns_log Notice "ad_check_file_for_sync called with \"$f\" and \"$db\""
    set url_stub [string range $f [string length [ns_info pageroot]] [expr [string length $f] -1]]
    ns_write "<li> $url_stub\n"
    set stream [open $f]
    set content [read $stream]
    close $stream
    # we don't want to mess with zero length files, esp. since they 
    # cause the Oracle driver to cough up an error
    if { [string length $content] == 0 } {
	ns_write " ... is zero length; not touching database."
	return 
    }
    if { ![regexp -nocase {<title>(.*)</title>} $content match page_title] } {
	set page_title "untitled document at $url_stub"
    }
    ns_write "([ns_quotehtml $page_title])\n"
    set n_rows_already [database_to_tcl_string $db "select count(*) as n_rows_already from static_pages where url_stub = '[DoubleApos $url_stub]'"]
    if { $n_rows_already == 0 } {
	ns_write "... not in database.  Preparing to stuff..."
	ns_ora clob_dml $db "insert into static_pages (page_id, url_stub, page_title, page_body)
values
(page_id_sequence.nextval, '[DoubleApos $url_stub]', '[DoubleApos $page_title]', empty_clob())
returning page_body into :1" $content
        ns_write "done!"
    } else {
	ns_write "... already in database."
    }
}

# we'll have an include pattern that is a REGEXP (single) 
# and an exclude_patterns which is a Tcl list of GLOB patterns

# the procedure must take two arguments, a filename and a database connection

# seen_already_cache is an ns_set

proc walk_tree {db dir procedure seen_already_cache {include_pattern {.*}} {exclude_patterns ""}} {
    # do this so that pwd works (so that we can avoid infinite loops)
    cd $dir

    set canonical_dirname [pwd]
    if { [ns_set find $seen_already_cache $canonical_dirname] != -1 } {
	# already exists
	if [ad_debug_static_page_syncer_p] {
	    ns_write "walk_tree: skipping directory $canonical_dirname (already seen)<br>"
	}
	return
    }

    # mark this directory as having been seen
    ns_set cput $seen_already_cache $canonical_dirname 1
    
    if [ad_debug_static_page_syncer_p] {
	ns_write "walk_tree: checking out directory $dir<br>\n"
    }
    foreach f [glob -nocomplain $dir/*] {
	if [file readable $f] {
	    if [file isdirectory $f] {
		if [ad_running_on_wimpy_machine_p] {
		    # we sleep for one second in order to not trash Web service
		    ns_sleep 1
		}
		walk_tree $db $f $procedure $seen_already_cache $include_pattern $exclude_patterns
	    } elseif [file isfile $f] {
		# the file is not a symlink
		set match [regexp $include_pattern $f]
		set excluded_p 0
		foreach pattern $exclude_patterns {
		    if { [string match $pattern $f] } {
			set excluded_p 1
			break
		    }
		}
		if { $match && !$excluded_p } {
		    $procedure $f $db
		}
	    }
	}
    }
}

ReturnHeaders

ns_write "<html>
<head>
<title>Syncing Pages at [ns_conn location]</title>
</head>
<body bgcolor=white text=black>
<h2>Syncing Pages</h2>

[ad_admin_context_bar [list "index.tcl" "Static Content"] "Syncing Static Pages"]


<hr>

All HTML files:
<ul>
"

# exclusion patterns
set exclude_patterns [list]

foreach pattern [ad_parameter_all_values_as_list "ExcludePattern" "static"] {
    lappend exclude_patterns "[ns_info pageroot]$pattern"
}

set db [ns_db gethandle]

# the include_pattern regexp defaults to .htm and .html
set inclusion_regexp [ad_parameter IncludeRegexp "static" {\.html?$}]

walk_tree $db [ns_info pageroot] ad_check_file_for_sync [ns_set new] $inclusion_regexp $exclude_patterns

ns_write "</ul><hr>
<address><a href=\"http://photo.net/philg/\">philg@mit.edu</a></address>
</body></html>
"
